# frozen_string_literal: true

class Snippet < ApplicationRecord
  include Gitlab::VisibilityLevel
  include Redactable
  include CacheMarkdownField
  include Noteable
  include Participable
  include Referable
  include Sortable
  include Awardable
  include Mentionable
  include Spammable
  include Editable
  include Gitlab::SQL::Pattern
  include FromUnion

  cache_markdown_field :title, pipeline: :single_line
  cache_markdown_field :description
  cache_markdown_field :content

  redact_field :description

  # Aliases to make application_helper#edited_time_ago_with_tooltip helper work properly with snippets.
  # See https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/10392/diffs#note_28719102
  alias_attribute :last_edited_at, :updated_at
  alias_attribute :last_edited_by, :updated_by

  # If file_name changes, it invalidates content
  alias_method :default_content_html_invalidator, :content_html_invalidated?
  def content_html_invalidated?
    default_content_html_invalidator || file_name_changed?
  end

  default_value_for(:visibility_level) { Gitlab::CurrentSettings.default_snippet_visibility }

  belongs_to :author, class_name: 'User'
  belongs_to :project

  has_many :notes, as: :noteable, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  delegate :name, :email, to: :author, prefix: true, allow_nil: true

  validates :author, presence: true
  validates :title, presence: true, length: { maximum: 255 }
  validates :file_name,
    length: { maximum: 255 }

  validates :content, presence: true
  validates :visibility_level, inclusion: { in: Gitlab::VisibilityLevel.values }

  # Scopes
  scope :are_internal, -> { where(visibility_level: Snippet::INTERNAL) }
  scope :are_private, -> { where(visibility_level: Snippet::PRIVATE) }
  scope :are_public, -> { where(visibility_level: Snippet::PUBLIC) }
  scope :public_and_internal, -> { where(visibility_level: [Snippet::PUBLIC, Snippet::INTERNAL]) }
  scope :fresh, -> { order("created_at DESC") }
  scope :inc_author, -> { includes(:author) }
  scope :inc_relations_for_view, -> { includes(author: :status) }

  participant :author
  participant :notes_with_associations

  attr_spammable :title, spam_title: true
  attr_spammable :content, spam_description: true

  def self.with_optional_visibility(value = nil)
    if value
      where(visibility_level: value)
    else
      all
    end
  end

  def self.only_global_snippets
    where(project_id: nil)
  end

  def self.only_include_projects_visible_to(current_user = nil)
    levels = Gitlab::VisibilityLevel.levels_for_user(current_user)

    joins(:project).where('projects.visibility_level IN (?)', levels)
  end

  def self.only_include_projects_with_snippets_enabled(include_private: false)
    column = ProjectFeature.access_level_attribute(:snippets)
    levels = [ProjectFeature::ENABLED, ProjectFeature::PUBLIC]

    levels << ProjectFeature::PRIVATE if include_private

    joins(project: :project_feature)
      .where(project_features: { column => levels })
  end

  def self.only_include_authorized_projects(current_user)
    where(
      'EXISTS (?)',
      ProjectAuthorization
        .select(1)
        .where('project_id = snippets.project_id')
        .where(user_id: current_user.id)
    )
  end

  def self.for_project_with_user(project, user = nil)
    return none unless project.snippets_visible?(user)

    if user && project.team.member?(user)
      project.snippets
    else
      project.snippets.public_to_user(user)
    end
  end

  def self.visible_to_or_authored_by(user)
    where(
      'snippets.visibility_level IN (?) OR snippets.author_id = ?',
      Gitlab::VisibilityLevel.levels_for_user(user),
      user.id
    )
  end

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

  def to_reference(from = nil, full: false)
    reference = "#{self.class.reference_prefix}#{id}"

    if project.present?
      "#{project.to_reference(from, full: full)}#{reference}"
    else
      reference
    end
  end

  def self.content_types
    [
      ".rb", ".py", ".pl", ".scala", ".c", ".cpp", ".java",
      ".haml", ".html", ".sass", ".scss", ".xml", ".php", ".erb",
      ".js", ".sh", ".coffee", ".yml", ".md"
    ]
  end

  def blob
    @blob ||= Blob.decorate(SnippetBlob.new(self), nil)
  end

  def hook_attrs
    attributes
  end

  def file_name
    super.to_s
  end

  def sanitized_file_name
    file_name.gsub(/[^a-zA-Z0-9_\-\.]+/, '')
  end

  def visibility_level_field
    :visibility_level
  end

  def embeddable?
    ability = project_id? ? :read_project_snippet : :read_personal_snippet

    Ability.allowed?(nil, ability, self)
  end

  def notes_with_associations
    notes.includes(:author)
  end

  def check_for_spam?
    visibility_level_changed?(to: Snippet::PUBLIC) ||
      (public? && (title_changed? || content_changed?))
  end

  def spammable_entity_type
    'snippet'
  end

  def to_ability_name
    model_name.singular
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
      fuzzy_search(query, [:title, :file_name])
    end

    # Searches for snippets with matching content.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query - The search query as a String.
    #
    # Returns an ActiveRecord::Relation.
    def search_code(query)
      fuzzy_search(query, [:content])
    end

    def parent_class
      ::Project
    end
  end
end
