# frozen_string_literal: true

# rubocop:disable Rails/ActiveRecordAliases
class WikiPage
  PageChangedError = Class.new(StandardError)
  PageRenameError = Class.new(StandardError)

  include ActiveModel::Validations
  include ActiveModel::Conversion
  include StaticModel
  extend ActiveModel::Naming

  def self.primary_key
    'slug'
  end

  def self.model_name
    ActiveModel::Name.new(self, nil, 'wiki')
  end

  # Sorts and groups pages by directory.
  #
  # pages - an array of WikiPage objects.
  #
  # Returns an array of WikiPage and WikiDirectory objects. The entries are
  # sorted by alphabetical order (directories and pages inside each directory).
  # Pages at the root level come before everything.
  def self.group_by_directory(pages)
    return [] if pages.blank?

    pages.each_with_object([]) do |page, grouped_pages|
      next grouped_pages << page unless page.directory.present?

      directory = grouped_pages.find do |obj|
        obj.is_a?(WikiDirectory) && obj.slug == page.directory
      end

      next directory.pages << page if directory

      grouped_pages << WikiDirectory.new(page.directory, [page])
    end
  end

  def self.unhyphenize(name)
    name.gsub(/-+/, ' ')
  end

  def to_key
    [:slug]
  end

  validates :title, presence: true
  validates :content, presence: true

  # The GitLab ProjectWiki instance.
  attr_reader :wiki

  # The raw Gitlab::Git::WikiPage instance.
  attr_reader :page

  # The attributes Hash used for storing and validating
  # new Page values before writing to the raw repository.
  attr_accessor :attributes

  def hook_attrs
    Gitlab::HookData::WikiPageBuilder.new(self).build
  end

  def initialize(wiki, page = nil, persisted = false)
    @wiki       = wiki
    @page       = page
    @persisted  = persisted
    @attributes = {}.with_indifferent_access

    set_attributes if persisted?
  end

  # The escaped URL path of this page.
  def slug
    @attributes[:slug].presence || wiki.wiki.preview_slug(title, format)
  end

  alias_method :to_param, :slug

  def human_title
    return 'Home' if title == 'home'

    title
  end

  # The formatted title of this page.
  def title
    if @attributes[:title]
      CGI.unescape_html(self.class.unhyphenize(@attributes[:title]))
    else
      ""
    end
  end

  # Sets the title of this page.
  def title=(new_title)
    @attributes[:title] = new_title
  end

  # The raw content of this page.
  def content
    @attributes[:content] ||= @page&.text_data
  end

  # The hierarchy of the directory this page is contained in.
  def directory
    wiki.page_title_and_dir(slug)&.last.to_s
  end

  # The markup format for the page.
  def format
    @attributes[:format] || :markdown
  end

  # The commit message for this page version.
  def message
    version.try(:message)
  end

  # The GitLab Commit instance for this page.
  def version
    return unless persisted?

    @version ||= @page.version
  end

  def path
    return unless persisted?

    @path ||= @page.path
  end

  def versions(options = {})
    return [] unless persisted?

    wiki.wiki.page_versions(@page.path, options)
  end

  def count_versions
    return [] unless persisted?

    wiki.wiki.count_page_versions(@page.path)
  end

  def last_version
    @last_version ||= versions(limit: 1).first
  end

  def last_commit_sha
    last_version&.sha
  end

  # Returns boolean True or False if this instance
  # is an old version of the page.
  def historical?
    return false unless last_commit_sha && version

    @page.historical? && last_commit_sha != version.sha
  end

  # Returns boolean True or False if this instance
  # is the latest commit version of the page.
  def latest?
    !historical?
  end

  # Returns boolean True or False if this instance
  # has been fully created on disk or not.
  def persisted?
    @persisted == true
  end

  # Creates a new Wiki Page.
  #
  # attr - Hash of attributes to set on the new page.
  #       :title   - The title (optionally including dir) for the new page.
  #       :content - The raw markup content.
  #       :format  - Optional symbol representing the
  #                  content format. Can be any type
  #                  listed in the ProjectWiki::MARKUPS
  #                  Hash.
  #       :message - Optional commit message to set on
  #                  the new page.
  #
  # Returns the String SHA1 of the newly created page
  # or False if the save was unsuccessful.
  def create(attrs = {})
    update_attributes(attrs)

    save(page_details: title) do
      wiki.create_page(title, content, format, attrs[:message])
    end
  end

  # Updates an existing Wiki Page, creating a new version.
  #
  # attrs - Hash of attributes to be updated on the page.
  #        :content         - The raw markup content to replace the existing.
  #        :format          - Optional symbol representing the content format.
  #                           See ProjectWiki::MARKUPS Hash for available formats.
  #        :message         - Optional commit message to set on the new version.
  #        :last_commit_sha - Optional last commit sha to validate the page unchanged.
  #        :title           - The Title (optionally including dir) to replace existing title
  #
  # Returns the String SHA1 of the newly created page
  # or False if the save was unsuccessful.
  def update(attrs = {})
    last_commit_sha = attrs.delete(:last_commit_sha)

    if last_commit_sha && last_commit_sha != self.last_commit_sha
      raise PageChangedError
    end

    update_attributes(attrs)

    if title_changed?
      page_details = title

      if wiki.find_page(page_details).present?
        @attributes[:title] = @page.url_path
        raise PageRenameError
      end
    else
      page_details = @page.url_path
    end

    save(page_details: page_details) do
      wiki.update_page(
        @page,
        content: content,
        format: format,
        message: attrs[:message],
        title: title
      )
    end
  end

  # Destroys the Wiki Page.
  #
  # Returns boolean True or False.
  def delete
    if wiki.delete_page(@page)
      true
    else
      false
    end
  end

  # Relative path to the partial to be used when rendering collections
  # of this object.
  def to_partial_path
    'projects/wikis/wiki_page'
  end

  def id
    page.version.to_s
  end

  def title_changed?
    title.present? && self.class.unhyphenize(@page.url_path) != title
  end

  # Updates the current @attributes hash by merging a hash of params
  def update_attributes(attrs)
    attrs[:title] = process_title(attrs[:title]) if attrs[:title].present?

    attrs.slice!(:content, :format, :message, :title)

    @attributes.merge!(attrs)
  end

  private

  # Process and format the title based on the user input.
  def process_title(title)
    return if title.blank?

    title = deep_title_squish(title)
    current_dirname = File.dirname(title)

    if @page.present?
      return title[1..-1] if current_dirname == '/'
      return File.join([directory.presence, title].compact) if current_dirname == '.'
    end

    title
  end

  # This method squishes all the filename
  # i.e: '   foo   /  bar  / page_name' => 'foo/bar/page_name'
  def deep_title_squish(title)
    components = title.split(File::SEPARATOR).map(&:squish)

    File.join(components)
  end

  def set_attributes
    attributes[:slug] = @page.url_path
    attributes[:title] = @page.title
    attributes[:format] = @page.format
  end

  def save(page_details:)
    return unless valid?

    unless yield
      errors.add(:base, wiki.error_message)
      return false
    end

    page_title, page_dir = wiki.page_title_and_dir(page_details)
    gitlab_git_wiki = wiki.wiki
    @page = gitlab_git_wiki.page(title: page_title, dir: page_dir)

    set_attributes
    @persisted = errors.blank?
  end
end
