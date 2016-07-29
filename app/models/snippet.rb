class Snippet < ActiveRecord::Base
  include Gitlab::VisibilityLevel
  include Linguist::BlobHelper
  include Participable
  include Referable
  include Sortable
  include Elastic::SnippetsSearch

  default_value_for :visibility_level, Snippet::PRIVATE

  belongs_to :author, class_name: 'User'
  belongs_to :project

  has_many :notes, as: :noteable, dependent: :destroy

  delegate :name, :email, to: :author, prefix: true, allow_nil: true

  validates :author, presence: true
  validates :title, presence: true, length: { within: 0..255 }
  validates :file_name,
    length: { within: 0..255 },
    format: { with: Gitlab::Regex.file_name_regex,
              message: Gitlab::Regex.file_name_regex_message }

  validates :content, presence: true
  validates :visibility_level, inclusion: { in: Gitlab::VisibilityLevel.values }

  # Scopes
  scope :are_internal,  -> { where(visibility_level: Snippet::INTERNAL) }
  scope :are_private, -> { where(visibility_level: Snippet::PRIVATE) }
  scope :are_public, -> { where(visibility_level: Snippet::PUBLIC) }
  scope :public_and_internal, -> { where(visibility_level: [Snippet::PUBLIC, Snippet::INTERNAL]) }
  scope :fresh,   -> { order("created_at DESC") }

  participant :author
  participant :notes_with_associations

  def self.reference_prefix
    '$'
  end

  # Pattern used to extract `$123` snippet references from text
  #
  # This pattern supports cross-project references.
  def self.reference_pattern
    @reference_pattern ||= %r{
      (#{Project.reference_pattern})?
      #{Regexp.escape(reference_prefix)}(?<snippet>\d+)
    }x
  end

  def self.link_reference_pattern
    @link_reference_pattern ||= super("snippets", /(?<snippet>\d+)/)
  end

  def to_reference(from_project = nil)
    reference = "#{self.class.reference_prefix}#{id}"

    if cross_project_reference?(from_project)
      reference = project.to_reference + reference
    end

    reference
  end

  def self.content_types
    [
      ".rb", ".py", ".pl", ".scala", ".c", ".cpp", ".java",
      ".haml", ".html", ".sass", ".scss", ".xml", ".php", ".erb",
      ".js", ".sh", ".coffee", ".yml", ".md"
    ]
  end

  def data
    content
  end

  def hook_attrs
    attributes
  end

  def size
    0
  end

  # alias for compatibility with blobs and highlighting
  def path
    file_name
  end

  def name
    file_name
  end

  def sanitized_file_name
    file_name.gsub(/[^a-zA-Z0-9_\-\.]+/, '')
  end

  def mode
    nil
  end

  def visibility_level_field
    visibility_level
  end

  def no_highlighting?
    content.lines.count > 1000
  end

  def notes_with_associations
    notes.includes(:author)
  end

  class << self
    # Searches for snippets with a matching title or file name.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query - The search query as a String.
    #
    # Returns an ActiveRecord::Relation.
    def search(query)
      t = arel_table
      pattern = "%#{query}%"

      where(t[:title].matches(pattern).or(t[:file_name].matches(pattern)))
    end

    # Searches for snippets with matching content.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query - The search query as a String.
    #
    # Returns an ActiveRecord::Relation.
    def search_code(query)
      table   = Snippet.arel_table
      pattern = "%#{query}%"

      where(table[:content].matches(pattern))
    end

    def accessible_to(user)
      return are_public unless user.present?
      return all if user.admin?

      where(
        'visibility_level IN (:visibility_levels)
         OR author_id = :author_id
         OR project_id IN (:project_ids)',
         visibility_levels: [Snippet::PUBLIC, Snippet::INTERNAL],
         author_id: user.id,
         project_ids: user.authorized_projects.select(:id))
    end
  end
end
