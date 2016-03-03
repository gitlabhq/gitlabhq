class WikiPage
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

  def to_key
    [:slug]
  end

  validates :title, presence: true
  validates :content, presence: true

  # The Gitlab ProjectWiki instance.
  attr_reader :wiki

  # The raw Gollum::Page instance.
  attr_reader :page

  # The attributes Hash used for storing and validating
  # new Page values before writing to the Gollum repository.
  attr_accessor :attributes

  def initialize(wiki, page = nil, persisted = false)
    @wiki       = wiki
    @page       = page
    @persisted  = persisted
    @attributes = {}.with_indifferent_access

    set_attributes if persisted?
  end

  # The escaped URL path of this page.
  def slug
    @attributes[:slug]
  end

  alias_method :to_param, :slug

  # The formatted title of this page.
  def title
    if @attributes[:title]
      @attributes[:title].gsub(/-+/, ' ')
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
    @attributes[:content] ||= if @page
                                @page.raw_data
                              end
  end

  # The processed/formatted content of this page.
  def formatted_content
    @attributes[:formatted_content] ||= if @page
                                          @page.formatted_data
                                        end
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

  # Returns an array of Gitlab Commit instances.
  def versions
    return [] unless persisted?

    @page.versions
  end

  def commit
    versions.first
  end

  # Returns the Date that this latest version was
  # created on.
  def created_at
    @page.version.date
  end

  # Returns boolean True or False if this instance
  # is an old version of the page.
  def historical?
    @page.historical? && versions.first.sha != version.sha
  end

  # Returns boolean True or False if this instance
  # has been fully saved to disk or not.
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
  def create(attr = {})
    @attributes.merge!(attr)

    save :create_page, title, content, format, message
  end

  # Updates an existing Wiki Page, creating a new version.
  #
  # new_content - The raw markup content to replace the existing.
  # format      - Optional symbol representing the content format.
  #               See ProjectWiki::MARKUPS Hash for available formats.
  # message     - Optional commit message to set on the new version.
  #
  # Returns the String SHA1 of the newly created page
  # or False if the save was unsuccessful.
  def update(new_content = "", format = :markdown, message = nil)
    @attributes[:content] = new_content
    @attributes[:format] = format

    save :update_page, @page, content, format, message
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

  private

  def set_attributes
    attributes[:slug] = @page.url_path
    attributes[:title] = @page.title
    attributes[:format] = @page.format
  end

  def save(method, *args)
    project_wiki = wiki
    if valid? && project_wiki.send(method, *args)

      page_details = if method == :update_page
                       # Use url_path instead of path to omit format extension
                       @page.url_path
                     else
                       title
                     end

      page_title, page_dir = project_wiki.page_title_and_dir(page_details)
      gollum_wiki = project_wiki.wiki
      @page = gollum_wiki.paged(page_title, page_dir)

      set_attributes

      @persisted = true
    else
      errors.add(:base, project_wiki.error_message) if project_wiki.error_message
      @persisted = false
    end
    @persisted
  end
end
