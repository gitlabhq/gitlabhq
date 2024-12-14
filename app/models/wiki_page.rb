# frozen_string_literal: true

# rubocop:disable Rails/ActiveRecordAliases
class WikiPage
  include Gitlab::Utils::StrongMemoize

  PageChangedError = Class.new(StandardError)
  PageRenameError = Class.new(StandardError)
  FrontMatterTooLong = Class.new(StandardError)

  include ActiveModel::Validations
  include ActiveModel::Conversion
  include StaticModel
  extend ActiveModel::Naming

  delegate :content, :front_matter, to: :parsed_content

  def self.primary_key
    'slug'
  end

  def self.model_name
    ActiveModel::Name.new(self, nil, 'wiki')
  end

  def eql?(other)
    return false unless other.present? && other.is_a?(self.class)

    slug == other.slug && wiki.container == other.wiki.container
  end

  alias_method :==, :eql?

  def self.unhyphenize(name)
    name.gsub(/-+/, ' ')
  end

  def to_key
    [:slug]
  end

  validates :title, presence: true
  validate :validate_path_limits, if: :title_changed?
  validate :validate_content_size_limit, if: :content_changed?

  # The GitLab Wiki instance.
  attr_reader :wiki

  delegate :container, to: :wiki

  # The raw Gitlab::Git::WikiPage instance.
  attr_reader :page

  # The attributes Hash used for storing and validating
  # new Page values before writing to the raw repository.
  attr_accessor :attributes

  def hook_attrs
    Gitlab::HookData::WikiPageBuilder.new(self).build
  end

  # Construct a new WikiPage
  #
  # @param [Wiki] wiki
  # @param [Gitlab::Git::WikiPage] page
  def initialize(wiki, page = nil)
    @wiki       = wiki
    @page       = page
    @attributes = {}.with_indifferent_access

    set_attributes if persisted?
  end

  def meta
    WikiPage::Meta.find_by_canonical_slug(slug, container)
  end

  # The escaped URL path of this page.
  def slug
    attributes[:slug].presence || ::Wiki.preview_slug(title, format)
  end
  alias_method :id, :slug # required to use build_stubbed

  alias_method :to_param, :slug

  def human_title
    return front_matter_title if front_matter_title.present?
    return 'Home' if title == Wiki::HOMEPAGE

    title
  end

  # The formatted title of this page.
  def title
    attributes[:title] || ''
  end

  # Sets the title of this page.
  def title=(new_title)
    attributes[:title] = new_title
  end

  def front_matter_title
    front_matter[:title]
  end

  def raw_content
    attributes[:content] ||= page&.text_data
  end

  def raw_content=(content)
    return if page.nil?

    page.raw_data = content
    attributes[:content] = page.text_data
  end

  # The hierarchy of the directory this page is contained in.
  def directory
    wiki.page_title_and_dir(slug)&.last.to_s
  end

  # The markup format for the page.
  def format
    attributes[:format] || :markdown
  end

  # The commit message for this page version.
  def message
    version.try(:message)
  end

  # The GitLab Commit instance for this page.
  def version
    return unless persisted?

    @version ||= @page.version || last_version
  end

  def path
    return unless persisted?

    @path ||= @page.path
  end

  # Returns a CommitCollection
  #
  # Queries the commits for current page's path, equivalent to
  # `git log path/to/page`. Filters and options supported:
  # https://gitlab.com/gitlab-org/gitaly/-/blob/master/proto/commit.proto#L322-344
  def versions(options = {})
    return [] unless persisted?

    default_per_page = Kaminari.config.default_per_page
    offset = [options[:page].to_i - 1, 0].max * options.fetch(:per_page, default_per_page)

    wiki.repository.commits(
      wiki.default_branch,
      path: page.path,
      limit: options.fetch(:limit, default_per_page),
      offset: offset
    )
  end

  def count_versions
    return [] unless persisted?

    wiki.repository.count_commits(ref: wiki.default_branch, path: page.path)
  end

  def last_version
    @last_version ||= wiki.repository.last_commit_for_path(wiki.default_branch, page.path) if page
  end

  def last_commit_sha
    last_version&.sha
  end

  def template?
    slug.start_with?(Wiki::TEMPLATES_DIR)
  end

  # Returns boolean True or False if this instance
  # is an old version of the page.
  def historical?
    return false unless last_commit_sha && version

    page.historical? && last_commit_sha != version.sha
  end

  # Returns boolean True or False if this instance
  # is the latest commit version of the page.
  def latest?
    !historical?
  end

  # Returns boolean True or False if this instance
  # has been fully created on disk or not.
  def persisted?
    page.present?
  end

  # Creates a new Wiki Page.
  #
  # attr - Hash of attributes to set on the new page.
  #       :title   - The title (optionally including dir) for the new page.
  #       :content - The raw markup content.
  #       :format  - Optional symbol representing the
  #                  content format. Can be any type
  #                  listed in the Wiki::VALID_USER_MARKUPS
  #                  Hash.
  #       :message - Optional commit message to set on
  #                  the new page.
  #
  # Returns the String SHA1 of the newly created page
  # or False if the save was unsuccessful.
  def create(attrs = {})
    update_attributes(attrs)

    save do
      wiki.create_page(title, raw_content, format, attrs[:message])
    end
  end

  # Updates an existing Wiki Page, creating a new version.
  #
  # attrs - Hash of attributes to be updated on the page.
  #        :content         - The raw markup content to replace the existing.
  #        :format          - Optional symbol representing the content format.
  #                           See Wiki::VALID_USER_MARKUPS Hash for available formats.
  #        :message         - Optional commit message to set on the new version.
  #        :last_commit_sha - Optional last commit sha to validate the page unchanged.
  #        :title           - The Title (optionally including dir) to replace existing title
  #
  # Returns the String SHA1 of the newly created page
  # or False if the save was unsuccessful.
  def update(attrs = {})
    last_commit_sha = attrs.delete(:last_commit_sha)

    if last_commit_sha && last_commit_sha != self.last_commit_sha
      raise PageChangedError, s_(
        'WikiPageConflictMessage|Someone edited the page the same time you did. Please check out %{wikiLinkStart}the page%{wikiLinkEnd} and make sure your changes will not unintentionally remove theirs.')
    end

    update_attributes(attrs)

    if title.present? && title_changed? && wiki.find_page(title, load_content: false).present?
      attributes[:title] = page.title
      raise PageRenameError, s_('WikiEdit|There is already a page with the same title in that path.')
    end

    save do
      wiki.update_page(
        page,
        content: raw_content,
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
    if wiki.delete_page(page)
      true
    else
      false
    end
  end

  # Relative path to the partial to be used when rendering collections
  # of this object.
  def to_partial_path
    'shared/wikis/wiki_page'
  end

  def sha
    page.version&.sha
  end

  def title_changed?
    if persisted?
      # A page's `title` will be returned from Gollum/Gitaly with any +<>
      # characters changed to -, whereas the `path` preserves these characters.
      path_without_extension = Pathname(page.path).sub_ext('').to_s
      old_title, old_dir = wiki.page_title_and_dir(self.class.unhyphenize(path_without_extension))
      new_title, new_dir = wiki.page_title_and_dir(self.class.unhyphenize(title))

      new_title != old_title || (title.include?('/') && new_dir != old_dir)
    else
      title.present?
    end
  end

  def content_changed?
    if persisted?
      # To avoid end-of-line differences depending if Git is enforcing CRLF or not,
      # we compare just the Wiki Content.
      raw_content.lines(chomp: true) != page&.text_data&.lines(chomp: true)
    else
      raw_content.present?
    end
  end

  # Updates the current @attributes hash by merging a hash of params
  def update_attributes(attrs)
    attrs[:title] = process_title(attrs[:title]) if attrs[:title].present?
    update_front_matter(attrs)

    attrs.slice!(:content, :format, :message, :title)
    clear_memoization(:parsed_content) if attrs.has_key?(:content)

    attributes.merge!(attrs)
  end

  def to_ability_name
    'wiki_page'
  end

  def version_commit_timestamp
    version&.commit&.committed_date
  end

  def diffs(diff_options = {})
    Gitlab::Diff::FileCollection::WikiPage.new(self, diff_options: diff_options)
  end

  private

  def serialize_front_matter(hash)
    return '' unless hash.present?

    YAML.dump(hash.to_h.transform_keys(&:to_s)) + "---\n"
  end

  def update_front_matter(attrs)
    return unless attrs.has_key?(:front_matter)

    fm_yaml = serialize_front_matter(attrs[:front_matter])
    raise FrontMatterTooLong if fm_yaml.size > Gitlab::WikiPages::FrontMatterParser::MAX_FRONT_MATTER_LENGTH

    attrs[:content] = fm_yaml + (attrs[:content].presence || content)
  end

  def parsed_content
    strong_memoize(:parsed_content) do
      Gitlab::WikiPages::FrontMatterParser.new(raw_content).parse
    end
  end

  # Process and format the title based on the user input.
  def process_title(title)
    return if title.blank?

    title = deep_title_squish(title)
    current_dirname = File.dirname(title)

    if persisted?
      return title[1..] if current_dirname == '/'
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

  def save
    return false unless valid?

    unless yield
      errors.add(:base, wiki.error_message)
      return false
    end

    @page = wiki.find_page(::Wiki.sluggified_title(title)).page
    set_attributes

    true
  end

  def validate_path_limits
    return unless title.present?

    *dirnames, filename = title.split('/')

    if filename && filename.bytesize > Gitlab::WikiPages::MAX_TITLE_BYTES
      errors.add(:title, _("exceeds the limit of %{bytes} bytes") % {
        bytes: Gitlab::WikiPages::MAX_TITLE_BYTES
      })
    end

    invalid_dirnames = dirnames.select { |d| d.bytesize > Gitlab::WikiPages::MAX_DIRECTORY_BYTES }
    invalid_dirnames.each do |dirname|
      errors.add(:title, _('exceeds the limit of %{bytes} bytes for directory name "%{dirname}"') % {
        bytes: Gitlab::WikiPages::MAX_DIRECTORY_BYTES,
        dirname: dirname
      })
    end
  end

  def validate_content_size_limit
    current_value = raw_content.to_s.bytesize
    max_size = Gitlab::CurrentSettings.wiki_page_max_content_bytes
    return if current_value <= max_size

    errors.add(:content, _('is too long (%{current_value}). The maximum size is %{max_size}.') % {
      current_value: ActiveSupport::NumberHelper.number_to_human_size(current_value),
      max_size: ActiveSupport::NumberHelper.number_to_human_size(max_size)
    })
  end
end

WikiPage.prepend_mod
