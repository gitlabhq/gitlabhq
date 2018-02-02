class WikiPage
  PageChangedError = Class.new(StandardError)

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

    pages.sort_by { |page| [page.directory, page.slug] }
      .group_by(&:directory)
      .map do |dir, pages|
        if dir.present?
          WikiDirectory.new(dir, pages)
        else
          pages
        end
      end
      .flatten
  end

  def self.unhyphenize(name)
    name.gsub(/-+/, ' ')
  end

  def to_key
    [:slug]
  end

  validates :title, presence: true
  validates :content, presence: true

  # The Gitlab ProjectWiki instance.
  attr_reader :wiki

  # The raw Gitlab::Git::WikiPage instance.
  attr_reader :page

  # The attributes Hash used for storing and validating
  # new Page values before writing to the Gollum repository.
  attr_accessor :attributes

  def hook_attrs
    attributes
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
    if @attributes[:slug].present?
      @attributes[:slug]
    else
      wiki.wiki.preview_slug(title, format)
    end
  end

  alias_method :to_param, :slug

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
    wiki.page_title_and_dir(slug).last
  end

  # The processed/formatted content of this page.
  def formatted_content
    # Assuming @page exists, nil formatted_data means we didn't load it
    # before hand (i.e. page was fetched by Gitaly), so we fetch it separately.
    # If the page was fetched by Gollum, formatted_data would've been a String.
    @attributes[:formatted_content] ||= @page&.formatted_data || @wiki.page_formatted_data(@page)
  end

  # The markup format for the page.
  def format
    @attributes[:format] || :markdown
  end

  # The commit message for this page version.
  def message
    version.try(:message)
  end

  # The Gitlab Commit instance for this page.
  def version
    return nil unless persisted?

    @version ||= @page.version
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

  # Returns the Date that this latest version was
  # created on.
  def created_at
    @page.version.date
  end

  # Returns boolean True or False if this instance
  # is an old version of the page.
  def historical?
    @page.historical? && last_version.sha != version.sha
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
  #       :title   - The title for the new page.
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
    @attributes.merge!(attrs)

    save(page_details: title) do
      wiki.create_page(title, content, format, message)
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
  #        :title           - The Title to replace existing title
  #
  # Returns the String SHA1 of the newly created page
  # or False if the save was unsuccessful.
  def update(attrs = {})
    last_commit_sha = attrs.delete(:last_commit_sha)
    if last_commit_sha && last_commit_sha != self.last_commit_sha
      raise PageChangedError.new("You are attempting to update a page that has changed since you started editing it.")
    end

    attrs.slice!(:content, :format, :message, :title)
    @attributes.merge!(attrs)
    page_details =
      if title.present? && @page.title != title
        title
      else
        @page.url_path
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

  private

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
