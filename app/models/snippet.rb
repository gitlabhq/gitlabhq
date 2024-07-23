# frozen_string_literal: true

class Snippet < ApplicationRecord
  include Gitlab::VisibilityLevel
  include Redactable
  include CacheMarkdownField
  include Noteable
  include Participable
  include Sortable
  include Awardable
  include Mentionable
  include Spammable
  include Editable
  include Gitlab::SQL::Pattern
  include FromUnion
  include HasRepository
  include CanMoveRepositoryStorage
  include AfterCommitQueue
  extend ::Gitlab::Utils::Override
  include CreatedAtFilterable
  include EachBatch
  include Import::HasImportSource

  MAX_FILE_COUNT = 10

  DESCRIPTION_LENGTH_MAX = 1.megabyte

  cache_markdown_field :title, pipeline: :single_line
  cache_markdown_field :description
  cache_markdown_field :content

  redact_field :description

  # Aliases to make application_helper#edited_time_ago_with_tooltip helper work properly with snippets.
  # See https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/10392/diffs#note_28719102
  alias_attribute :last_edited_at, :updated_at
  alias_attribute :last_edited_by, :updated_by

  # If file_name changes, it invalidates content
  alias_method :default_content_html_invalidator, :content_html_invalidated?
  def content_html_invalidated?
    default_content_html_invalidator || file_name_changed?
  end

  belongs_to :author, class_name: 'User'
  belongs_to :project
  belongs_to :organization, class_name: 'Organizations::Organization'
  alias_method :resource_parent, :project

  has_many :notes, as: :noteable, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :user_mentions, class_name: "SnippetUserMention", dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
  has_one :snippet_repository, inverse_of: :snippet
  has_many :repository_storage_moves, class_name: 'Snippets::RepositoryStorageMove', inverse_of: :container

  # We need to add the `dependent` in order to call the after_destroy callback
  has_one :statistics, class_name: 'SnippetStatistics', dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  delegate :name, :email, to: :author, prefix: true, allow_nil: true

  validates :author, presence: true
  validates :title, presence: true, length: { maximum: 255 }
  validates :file_name,
    length: { maximum: 255 }
  validates :description, bytesize: { maximum: -> { DESCRIPTION_LENGTH_MAX } }, if: :description_changed?

  validates :content, presence: true
  validates :content, bytesize: { maximum: -> { Gitlab::CurrentSettings.snippet_size_limit } }, if: :content_changed?

  after_create :create_statistics

  # Scopes
  scope :are_internal, -> { where(visibility_level: Snippet::INTERNAL) }
  scope :are_private, -> { where(visibility_level: Snippet::PRIVATE) }
  scope :are_public, -> { public_only }
  scope :are_secret, -> { public_only.where(secret: true) }
  scope :fresh, -> { order("created_at DESC") }
  scope :inc_author, -> { includes(:author) }
  scope :inc_relations_for_view, -> { includes(author: :status) }
  scope :inc_statistics, -> { includes(:statistics) }
  scope :with_statistics, -> { joins(:statistics) }
  scope :with_repository_storage_moves, -> { joins(:repository_storage_moves) }
  scope :inc_projects_namespace_route, -> { includes(project: [:route, :namespace]) }

  scope :without_created_by_banned_user, -> do
    where_not_exists(Users::BannedUser.where('snippets.author_id = banned_users.user_id'))
  end

  attr_mentionable :description

  participant :author
  participant :notes_with_associations

  attr_spammable :title, spam_title: true
  attr_spammable :description, spam_description: true

  attr_encrypted :secret_token,
    key: Settings.attr_encrypted_db_key_base_truncated,
    mode: :per_attribute_iv,
    algorithm: 'aes-256-cbc'

  class << self
    # Searches for snippets with a matching title, description or file name.
    #
    # This method uses ILIKE on PostgreSQL.
    #
    # query - The search query as a String.
    #
    # Returns an ActiveRecord::Relation.
    def search(query)
      fuzzy_search(query, [:title, :description, :file_name])
    end

    def parent_class
      ::Project
    end

    def sanitized_file_name(file_name)
      file_name.gsub(/[^a-zA-Z0-9_\-\.]+/, '')
    end

    def with_optional_visibility(value = nil)
      if value
        where(visibility_level: value)
      else
        all
      end
    end

    def only_personal_snippets
      where(project_id: nil)
    end

    def only_project_snippets
      where.not(project_id: nil)
    end

    def only_include_projects_visible_to(current_user = nil)
      levels = Gitlab::VisibilityLevel.levels_for_user(current_user)

      joins(:project).where(projects: { visibility_level: levels })
    end

    def only_include_projects_with_snippets_enabled(include_private: false)
      column = ProjectFeature.access_level_attribute(:snippets)
      levels = [ProjectFeature::ENABLED, ProjectFeature::PUBLIC]

      levels << ProjectFeature::PRIVATE if include_private

      joins(project: :project_feature)
        .where(project_features: { column => levels })
    end

    def only_include_authorized_projects(current_user)
      where(
        'EXISTS (?)',
        ProjectAuthorization
          .select(1)
          .where('project_id = snippets.project_id')
          .where(user_id: current_user.id)
      )
    end

    def for_project_with_user(project, user = nil)
      return none unless project.snippets_visible?(user)

      if project.member?(user)
        project.snippets
      else
        project.snippets.public_to_user(user)
      end
    end

    def visible_to_or_authored_by(user)
      query = where(visibility_level: Gitlab::VisibilityLevel.levels_for_user(user))
      query.or(where(author_id: user.id))
    end

    def reference_prefix
      '$'
    end

    # Pattern used to extract `$123` snippet references from text
    #
    # This pattern supports cross-project references.
    def reference_pattern
      @reference_pattern ||= %r{
      (#{Project.reference_pattern})?
      #{Regexp.escape(reference_prefix)}(?<snippet>\d+)
    }x
    end

    def link_reference_pattern
      @link_reference_pattern ||= compose_link_reference_pattern('snippets', /(?<snippet>\d+)/)
    end

    def find_by_id_and_project(id:, project:)
      Snippet.find_by(id: id, project: project)
    end

    def find_by_project_title_trunc_created_at(project, title, created_at)
      where(project: project, title: title)
        .find_by(
          "date_trunc('second', created_at at time zone :tz) at time zone :tz = :created_at",
          tz: created_at.zone, created_at: created_at)
    end

    def max_file_limit
      MAX_FILE_COUNT
    end
  end

  def initialize(attributes = {})
    # We assign the actual snippet default if no explicit visibility has been initialized.
    attributes ||= {}

    unless visibility_attribute_present?(attributes)
      attributes[:visibility_level] = Gitlab::CurrentSettings.default_snippet_visibility
    end

    super
  end

  def to_reference(from = nil, full: false)
    reference = "#{self.class.reference_prefix}#{id}"

    if project.present?
      "#{project.to_reference_base(from, full: full)}#{reference}"
    else
      reference
    end
  end

  def all_files
    list_files(default_branch)
  end

  def blob
    @blob ||= Blob.decorate(SnippetBlob.new(self), self)
  end

  def blobs(paths = [])
    return [] unless repository_exists?

    paths = all_files if paths.empty?
    items = paths.map { |path| [default_branch, path] }

    repository.blobs_at(items).compact
  end

  def hook_attrs
    {
      id: id,
      title: title,
      description: description,
      content: content,
      author_id: author_id,
      project_id: project_id,
      created_at: created_at,
      updated_at: updated_at,
      file_name: file_name,
      type: type,
      visibility_level: visibility_level,
      url: Gitlab::UrlBuilder.build(self)
    }
  end

  def file_name
    super.to_s
  end

  def visibility_level_field
    :visibility_level
  end

  def embeddable?
    Ability.allowed?(nil, :read_snippet, self)
  end

  def notes_with_associations
    notes.includes(:author)
  end

  def check_for_spam?(*)
    visibility_level_changed?(to: Snippet::PUBLIC) || (public? && spammable_attribute_changed?)
  end

  def supports_recaptcha?
    true
  end

  def to_ability_name
    'snippet'
  end

  def valid_secret_token?(token)
    return false unless token && secret_token

    ActiveSupport::SecurityUtils.secure_compare(token.to_s, secret_token.to_s)
  end

  def as_json(options = {})
    options[:except] = Array.wrap(options[:except])
    options[:except] << :secret_token

    super
  end

  override :repository
  def repository
    @repository ||= Gitlab::GlRepository::SNIPPET.repository_for(self)
  end

  override :repository_size_checker
  def repository_size_checker
    strong_memoize(:repository_size_checker) do
      ::Gitlab::RepositorySizeChecker.new(
        current_size_proc: -> { repository.size.megabytes },
        limit: Gitlab::CurrentSettings.snippet_size_limit,
        namespace: nil
      )
    end
  end

  override :storage
  def storage
    @storage ||= Storage::Hashed.new(self, prefix: Storage::Hashed::SNIPPET_REPOSITORY_PATH_PREFIX)
  end

  # This is the full_path used to identify the the snippet repository.
  override :full_path
  def full_path
    return unless persisted?

    @full_path ||= begin
      components = []
      components << project.full_path if project_id?
      components << 'snippets'
      components << self.id
      components.join('/')
    end
  end

  override :default_branch
  def default_branch
    super || Gitlab::DefaultBranch.value(object: project)
  end

  def repository_storage
    snippet_repository&.shard_name || Repository.pick_storage_shard
  end

  def create_repository
    return if repository_exists? && snippet_repository

    repository.create_if_not_exists(default_branch)
    track_snippet_repository(repository.storage)
  end

  def track_snippet_repository(shard)
    snippet_repo = snippet_repository || build_snippet_repository
    snippet_repo.update!(shard_name: shard, disk_path: disk_path)
  end

  def can_cache_field?(field)
    field != :content || Gitlab::MarkupHelper.gitlab_markdown?(file_name)
  end

  def hexdigest
    Digest::SHA256.hexdigest("#{title}#{description}#{created_at}#{updated_at}")
  end

  def file_name_on_repo
    return if repository.empty?

    list_files(default_branch).first
  end

  def list_files(ref = nil)
    return [] if repository.empty?

    repository.ls_files(ref || default_branch)
  end

  def multiple_files?
    list_files.size > 1
  end

  def hidden_due_to_author_ban?
    Feature.enabled?(:hide_snippets_of_banned_users) && author.banned?
  end
end

Snippet.prepend_mod_with('Snippet')
