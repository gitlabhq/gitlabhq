require 'carrierwave/orm/activerecord'

class Project < ActiveRecord::Base
  include Gitlab::ConfigHelper
  include Gitlab::ShellAdapter
  include Gitlab::VisibilityLevel
  include AccessRequestable
  include Avatarable
  include CacheMarkdownField
  include Referable
  include Sortable
  include AfterCommitQueue
  include CaseSensitivity
  include TokenAuthenticatable
  include ValidAttribute
  include ProjectFeaturesCompatibility
  include SelectForProjectAuthorization
  include Presentable
  include Routable
  include GroupDescendant
  include Gitlab::SQL::Pattern
  include DeploymentPlatform
  include ::Gitlab::Utils::StrongMemoize

  extend Gitlab::ConfigHelper

  BoardLimitExceeded = Class.new(StandardError)

  NUMBER_OF_PERMITTED_BOARDS = 1
  UNKNOWN_IMPORT_URL = 'http://unknown.git'.freeze
  # Hashed Storage versions handle rolling out new storage to project and dependents models:
  # nil: legacy
  # 1: repository
  # 2: attachments
  LATEST_STORAGE_VERSION = 2
  HASHED_STORAGE_FEATURES = {
    repository: 1,
    attachments: 2
  }.freeze

  cache_markdown_field :description, pipeline: :description

  delegate :feature_available?, :builds_enabled?, :wiki_enabled?,
           :merge_requests_enabled?, :issues_enabled?, to: :project_feature,
                                                       allow_nil: true

  delegate :base_dir, :disk_path, :ensure_storage_path_exists, to: :storage

  default_value_for :archived, false
  default_value_for :visibility_level, gitlab_config_features.visibility_level
  default_value_for :resolve_outdated_diff_discussions, false
  default_value_for :container_registry_enabled, gitlab_config_features.container_registry
  default_value_for(:repository_storage) { Gitlab::CurrentSettings.pick_repository_storage }
  default_value_for(:shared_runners_enabled) { Gitlab::CurrentSettings.shared_runners_enabled }
  default_value_for :issues_enabled, gitlab_config_features.issues
  default_value_for :merge_requests_enabled, gitlab_config_features.merge_requests
  default_value_for :builds_enabled, gitlab_config_features.builds
  default_value_for :wiki_enabled, gitlab_config_features.wiki
  default_value_for :snippets_enabled, gitlab_config_features.snippets
  default_value_for :only_allow_merge_if_all_discussions_are_resolved, false

  add_authentication_token_field :runners_token
  before_save :ensure_runners_token

  after_save :update_project_statistics, if: :namespace_id_changed?
  after_create :create_project_feature, unless: :project_feature
  after_create :set_last_activity_at
  after_create :set_last_repository_updated_at
  after_update :update_forks_visibility_level

  before_destroy :remove_private_deploy_keys
  after_destroy -> { run_after_commit { remove_pages } }
  after_destroy :remove_exports

  after_validation :check_pending_delete

  # Storage specific hooks
  after_initialize :use_hashed_storage
  after_create :check_repository_absence!
  after_create :ensure_storage_path_exists
  after_save :ensure_storage_path_exists, if: :namespace_id_changed?

  acts_as_taggable

  attr_accessor :old_path_with_namespace
  attr_accessor :template_name
  attr_writer :pipeline_status
  attr_accessor :skip_disk_validation

  alias_attribute :title, :name

  # Relations
  belongs_to :creator, class_name: 'User'
  belongs_to :group, -> { where(type: 'Group') }, foreign_key: 'namespace_id'
  belongs_to :namespace
  alias_method :parent, :namespace
  alias_attribute :parent_id, :namespace_id

  has_one :last_event, -> {order 'events.created_at DESC'}, class_name: 'Event'
  has_many :boards, before_add: :validate_board_limit

  # Project services
  has_one :campfire_service
  has_one :drone_ci_service
  has_one :emails_on_push_service
  has_one :pipelines_email_service
  has_one :irker_service
  has_one :pivotaltracker_service
  has_one :hipchat_service
  has_one :flowdock_service
  has_one :assembla_service
  has_one :asana_service
  has_one :gemnasium_service
  has_one :mattermost_slash_commands_service
  has_one :mattermost_service
  has_one :slack_slash_commands_service
  has_one :slack_service
  has_one :buildkite_service
  has_one :bamboo_service
  has_one :teamcity_service
  has_one :pushover_service
  has_one :jira_service
  has_one :redmine_service
  has_one :custom_issue_tracker_service
  has_one :bugzilla_service
  has_one :gitlab_issue_tracker_service, inverse_of: :project
  has_one :external_wiki_service
  has_one :kubernetes_service, inverse_of: :project
  has_one :prometheus_service, inverse_of: :project
  has_one :mock_ci_service
  has_one :mock_deployment_service
  has_one :mock_monitoring_service
  has_one :microsoft_teams_service
  has_one :packagist_service

  # TODO: replace these relations with the fork network versions
  has_one  :forked_project_link,  foreign_key: "forked_to_project_id"
  has_one  :forked_from_project,  through:   :forked_project_link

  has_many :forked_project_links, foreign_key: "forked_from_project_id"
  has_many :forks,                through:     :forked_project_links, source: :forked_to_project
  # TODO: replace these relations with the fork network versions

  has_one :root_of_fork_network,
          foreign_key: 'root_project_id',
          inverse_of: :root_project,
          class_name: 'ForkNetwork'
  has_one :fork_network_member
  has_one :fork_network, through: :fork_network_member

  # Merge Requests for target project should be removed with it
  has_many :merge_requests, foreign_key: 'target_project_id'
  has_many :source_of_merge_requests, foreign_key: 'source_project_id', class_name: 'MergeRequest'
  has_many :issues
  has_many :labels, class_name: 'ProjectLabel'
  has_many :services
  has_many :events
  has_many :milestones
  has_many :notes
  has_many :snippets, class_name: 'ProjectSnippet'
  has_many :hooks, class_name: 'ProjectHook'
  has_many :protected_branches
  has_many :protected_tags

  has_many :project_authorizations
  has_many :authorized_users, through: :project_authorizations, source: :user, class_name: 'User'
  has_many :project_members, -> { where(requested_at: nil) },
    as: :source, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  alias_method :members, :project_members
  has_many :users, through: :project_members

  has_many :requesters, -> { where.not(requested_at: nil) },
    as: :source, class_name: 'ProjectMember', dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
  has_many :members_and_requesters, as: :source, class_name: 'ProjectMember'

  has_many :deploy_keys_projects
  has_many :deploy_keys, through: :deploy_keys_projects
  has_many :users_star_projects
  has_many :starrers, through: :users_star_projects, source: :user
  has_many :releases
  has_many :lfs_objects_projects, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :lfs_objects, through: :lfs_objects_projects
  has_many :lfs_file_locks
  has_many :project_group_links
  has_many :invited_groups, through: :project_group_links, source: :group
  has_many :pages_domains
  has_many :todos
  has_many :notification_settings, as: :source, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  has_one :import_data, class_name: 'ProjectImportData', inverse_of: :project, autosave: true
  has_one :project_feature, inverse_of: :project
  has_one :statistics, class_name: 'ProjectStatistics'

  has_one :cluster_project, class_name: 'Clusters::Project'
  has_many :clusters, through: :cluster_project, class_name: 'Clusters::Cluster'

  # Container repositories need to remove data from the container registry,
  # which is not managed by the DB. Hence we're still using dependent: :destroy
  # here.
  has_many :container_repositories, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  has_many :commit_statuses
  has_many :pipelines, class_name: 'Ci::Pipeline', inverse_of: :project

  # Ci::Build objects store data on the file system such as artifact files and
  # build traces. Currently there's no efficient way of removing this data in
  # bulk that doesn't involve loading the rows into memory. As a result we're
  # still using `dependent: :destroy` here.
  has_many :builds, class_name: 'Ci::Build', inverse_of: :project, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :build_trace_section_names, class_name: 'Ci::BuildTraceSectionName'
  has_many :runner_projects, class_name: 'Ci::RunnerProject'
  has_many :runners, through: :runner_projects, source: :runner, class_name: 'Ci::Runner'
  has_many :variables, class_name: 'Ci::Variable'
  has_many :triggers, class_name: 'Ci::Trigger'
  has_many :environments
  has_many :deployments
  has_many :pipeline_schedules, class_name: 'Ci::PipelineSchedule'

  has_many :active_runners, -> { active }, through: :runner_projects, source: :runner, class_name: 'Ci::Runner'

  has_one :auto_devops, class_name: 'ProjectAutoDevops'
  has_many :custom_attributes, class_name: 'ProjectCustomAttribute'

  has_many :project_badges, class_name: 'ProjectBadge'

  accepts_nested_attributes_for :variables, allow_destroy: true
  accepts_nested_attributes_for :project_feature, update_only: true
  accepts_nested_attributes_for :import_data
  accepts_nested_attributes_for :auto_devops, update_only: true

  delegate :name, to: :owner, allow_nil: true, prefix: true
  delegate :members, to: :team, prefix: true
  delegate :add_user, :add_users, to: :team
  delegate :add_guest, :add_reporter, :add_developer, :add_master, :add_role, to: :team

  # Validations
  validates :creator, presence: true, on: :create
  validates :description, length: { maximum: 2000 }, allow_blank: true
  validates :ci_config_path,
    format: { without: %r{(\.{2}|\A/)},
              message: 'cannot include leading slash or directory traversal.' },
    length: { maximum: 255 },
    allow_blank: true
  validates :name,
    presence: true,
    length: { maximum: 255 },
    format: { with: Gitlab::Regex.project_name_regex,
              message: Gitlab::Regex.project_name_regex_message }
  validates :path,
    presence: true,
    project_path: true,
    length: { maximum: 255 }

  validates :namespace, presence: true
  validates :name, uniqueness: { scope: :namespace_id }
  validates :import_url, addressable_url: true, if: :external_import?
  validates :import_url, importable_url: true, if: [:external_import?, :import_url_changed?]
  validates :star_count, numericality: { greater_than_or_equal_to: 0 }
  validate :check_limit, on: :create
  validate :check_repository_path_availability, on: :update, if: ->(project) { project.renamed? }
  validate :visibility_level_allowed_by_group
  validate :visibility_level_allowed_as_fork
  validate :check_wiki_path_conflict
  validates :repository_storage,
    presence: true,
    inclusion: { in: ->(_object) { Gitlab.config.repositories.storages.keys } }
  validates :variables, variable_duplicates: { scope: :environment_scope }

  has_many :uploads, as: :model, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  # Scopes
  scope :pending_delete, -> { where(pending_delete: true) }
  scope :without_deleted, -> { where(pending_delete: false) }

  scope :with_storage_feature, ->(feature) { where('storage_version >= :version', version: HASHED_STORAGE_FEATURES[feature]) }
  scope :without_storage_feature, ->(feature) { where('storage_version < :version OR storage_version IS NULL', version: HASHED_STORAGE_FEATURES[feature]) }
  scope :with_unmigrated_storage, -> { where('storage_version < :version OR storage_version IS NULL', version: LATEST_STORAGE_VERSION) }

  # last_activity_at is throttled every minute, but last_repository_updated_at is updated with every push
  scope :sorted_by_activity, -> { reorder("GREATEST(COALESCE(last_activity_at, '1970-01-01'), COALESCE(last_repository_updated_at, '1970-01-01')) DESC") }
  scope :sorted_by_stars, -> { reorder('projects.star_count DESC') }

  scope :in_namespace, ->(namespace_ids) { where(namespace_id: namespace_ids) }
  scope :personal, ->(user) { where(namespace_id: user.namespace_id) }
  scope :joined, ->(user) { where('namespace_id != ?', user.namespace_id) }
  scope :starred_by, ->(user) { joins(:users_star_projects).where('users_star_projects.user_id': user.id) }
  scope :visible_to_user, ->(user) { where(id: user.authorized_projects.select(:id).reorder(nil)) }
  scope :archived, -> { where(archived: true) }
  scope :non_archived, -> { where(archived: false) }
  scope :for_milestones, ->(ids) { joins(:milestones).where('milestones.id' => ids).distinct }
  scope :with_push, -> { joins(:events).where('events.action = ?', Event::PUSHED) }
  scope :with_project_feature, -> { joins('LEFT JOIN project_features ON projects.id = project_features.project_id') }
  scope :with_statistics, -> { includes(:statistics) }
  scope :with_shared_runners, -> { where(shared_runners_enabled: true) }
  scope :inside_path, ->(path) do
    # We need routes alias rs for JOIN so it does not conflict with
    # includes(:route) which we use in ProjectsFinder.
    joins("INNER JOIN routes rs ON rs.source_id = projects.id AND rs.source_type = 'Project'")
      .where('rs.path LIKE ?', "#{sanitize_sql_like(path)}/%")
  end

  # "enabled" here means "not disabled". It includes private features!
  scope :with_feature_enabled, ->(feature) {
    access_level_attribute = ProjectFeature.access_level_attribute(feature)
    with_project_feature.where(project_features: { access_level_attribute => [nil, ProjectFeature::PRIVATE, ProjectFeature::ENABLED] })
  }

  # Picks a feature where the level is exactly that given.
  scope :with_feature_access_level, ->(feature, level) {
    access_level_attribute = ProjectFeature.access_level_attribute(feature)
    with_project_feature.where(project_features: { access_level_attribute => level })
  }

  scope :with_builds_enabled, -> { with_feature_enabled(:builds) }
  scope :with_issues_enabled, -> { with_feature_enabled(:issues) }
  scope :with_issues_available_for_user, ->(current_user) { with_feature_available_for_user(:issues, current_user) }
  scope :with_merge_requests_enabled, -> { with_feature_enabled(:merge_requests) }

  enum auto_cancel_pending_pipelines: { disabled: 0, enabled: 1 }

  # Returns a collection of projects that is either public or visible to the
  # logged in user.
  def self.public_or_visible_to_user(user = nil)
    if user
      where('EXISTS (?) OR projects.visibility_level IN (?)',
            user.authorizations_for_projects,
            Gitlab::VisibilityLevel.levels_for_user(user))
    else
      public_to_user
    end
  end

  # project features may be "disabled", "internal" or "enabled". If "internal",
  # they are only available to team members. This scope returns projects where
  # the feature is either enabled, or internal with permission for the user.
  #
  # This method uses an optimised version of `with_feature_access_level` for
  # logged in users to more efficiently get private projects with the given
  # feature.
  def self.with_feature_available_for_user(feature, user)
    visible = [nil, ProjectFeature::ENABLED]

    if user&.admin?
      with_feature_enabled(feature)
    elsif user
      column = ProjectFeature.quoted_access_level_column(feature)

      with_project_feature
        .where("#{column} IN (?) OR (#{column} = ? AND EXISTS (?))",
              visible,
              ProjectFeature::PRIVATE,
              user.authorizations_for_projects)
    else
      with_feature_access_level(feature, visible)
    end
  end

  scope :active, -> { joins(:issues, :notes, :merge_requests).order('issues.created_at, notes.created_at, merge_requests.created_at DESC') }
  scope :abandoned, -> { where('projects.last_activity_at < ?', 6.months.ago) }

  scope :excluding_project, ->(project) { where.not(id: project) }
  scope :import_started, -> { where(import_status: 'started') }

  state_machine :import_status, initial: :none do
    event :import_schedule do
      transition [:none, :finished, :failed] => :scheduled
    end

    event :force_import_start do
      transition [:none, :finished, :failed] => :started
    end

    event :import_start do
      transition scheduled: :started
    end

    event :import_finish do
      transition started: :finished
    end

    event :import_fail do
      transition [:scheduled, :started] => :failed
    end

    event :import_retry do
      transition failed: :started
    end

    state :scheduled
    state :started
    state :finished
    state :failed

    after_transition [:none, :finished, :failed] => :scheduled do |project, _|
      project.run_after_commit do
        job_id = add_import_job
        update(import_jid: job_id) if job_id
      end
    end

    after_transition started: :finished do |project, _|
      project.reset_cache_and_import_attrs

      if Gitlab::ImportSources.importer_names.include?(project.import_type) && project.repo_exists?
        project.run_after_commit do
          Projects::AfterImportService.new(project).execute
        end
      end
    end
  end

  class << self
    # Searches for a list of projects based on the query given in `query`.
    #
    # On PostgreSQL this method uses "ILIKE" to perform a case-insensitive
    # search. On MySQL a regular "LIKE" is used as it's already
    # case-insensitive.
    #
    # query - The search query as a String.
    def search(query)
      fuzzy_search(query, [:path, :name, :description])
    end

    def search_by_title(query)
      non_archived.fuzzy_search(query, [:name])
    end

    def visibility_levels
      Gitlab::VisibilityLevel.options
    end

    def sort(method)
      case method.to_s
      when 'storage_size_desc'
        # storage_size is a joined column so we need to
        # pass a string to avoid AR adding the table name
        reorder('project_statistics.storage_size DESC, projects.id DESC')
      when 'latest_activity_desc'
        reorder(last_activity_at: :desc)
      when 'latest_activity_asc'
        reorder(last_activity_at: :asc)
      else
        order_by(method)
      end
    end

    def reference_pattern
      %r{
        ((?<namespace>#{Gitlab::PathRegex::FULL_NAMESPACE_FORMAT_REGEX})\/)?
        (?<project>#{Gitlab::PathRegex::PROJECT_PATH_FORMAT_REGEX})
      }x
    end

    def trending
      joins('INNER JOIN trending_projects ON projects.id = trending_projects.project_id')
        .reorder('trending_projects.id ASC')
    end

    def cached_count
      Rails.cache.fetch('total_project_count', expires_in: 5.minutes) do
        Project.count
      end
    end

    def group_ids
      joins(:namespace).where(namespaces: { type: 'Group' }).select(:namespace_id)
    end
  end

  # returns all ancestor-groups upto but excluding the given namespace
  # when no namespace is given, all ancestors upto the top are returned
  def ancestors_upto(top = nil)
    Gitlab::GroupHierarchy.new(Group.where(id: namespace_id))
      .base_and_ancestors(upto: top)
  end

  def lfs_enabled?
    return namespace.lfs_enabled? if self[:lfs_enabled].nil?

    self[:lfs_enabled] && Gitlab.config.lfs.enabled
  end

  def auto_devops_enabled?
    if auto_devops&.enabled.nil?
      Gitlab::CurrentSettings.auto_devops_enabled?
    else
      auto_devops.enabled?
    end
  end

  def has_auto_devops_implicitly_disabled?
    auto_devops&.enabled.nil? && !Gitlab::CurrentSettings.auto_devops_enabled?
  end

  def empty_repo?
    repository.empty?
  end

  def repository_storage_path
    Gitlab.config.repositories.storages[repository_storage]&.legacy_disk_path
  end

  def team
    @team ||= ProjectTeam.new(self)
  end

  def repository
    @repository ||= Repository.new(full_path, self, disk_path: disk_path)
  end

  def cleanup
    @repository&.cleanup
    @repository = nil
  end

  alias_method :reload_repository!, :cleanup

  def container_registry_url
    if Gitlab.config.registry.enabled
      "#{Gitlab.config.registry.host_port}/#{full_path.downcase}"
    end
  end

  def has_container_registry_tags?
    return @images if defined?(@images)

    @images = container_repositories.to_a.any?(&:has_tags?) ||
      has_root_container_repository_tags?
  end

  def commit(ref = 'HEAD')
    repository.commit(ref)
  end

  def commit_by(oid:)
    repository.commit_by(oid: oid)
  end

  # ref can't be HEAD, can only be branch/tag name or SHA
  def latest_successful_builds_for(ref = default_branch)
    latest_pipeline = pipelines.latest_successful_for(ref)

    if latest_pipeline
      latest_pipeline.builds.latest.with_artifacts
    else
      builds.none
    end
  end

  def merge_base_commit(first_commit_id, second_commit_id)
    sha = repository.merge_base(first_commit_id, second_commit_id)
    commit_by(oid: sha) if sha
  end

  def saved?
    id && persisted?
  end

  def add_import_job
    job_id =
      if forked?
        RepositoryForkWorker.perform_async(id,
                                           forked_from_project.repository_storage_path,
                                           forked_from_project.disk_path)
      elsif gitlab_project_import?
        # Do not retry on Import/Export until https://gitlab.com/gitlab-org/gitlab-ce/issues/26189 is solved.
        RepositoryImportWorker.set(retry: false).perform_async(self.id)
      else
        RepositoryImportWorker.perform_async(self.id)
      end

    log_import_activity(job_id)

    job_id
  end

  def log_import_activity(job_id, type: :import)
    job_type = type.to_s.capitalize

    if job_id
      Rails.logger.info("#{job_type} job scheduled for #{full_path} with job ID #{job_id}.")
    else
      Rails.logger.error("#{job_type} job failed to create for #{full_path}.")
    end
  end

  def reset_cache_and_import_attrs
    run_after_commit do
      ProjectCacheWorker.perform_async(self.id)
    end

    update(import_error: nil)
    remove_import_data
  end

  # This method is overriden in EE::Project model
  def remove_import_data
    import_data&.destroy
  end

  def ci_config_path=(value)
    # Strip all leading slashes so that //foo -> foo
    super(value&.delete("\0"))
  end

  def import_url=(value)
    return super(value) unless Gitlab::UrlSanitizer.valid?(value)

    import_url = Gitlab::UrlSanitizer.new(value)
    super(import_url.sanitized_url)
    create_or_update_import_data(credentials: import_url.credentials)
  end

  def import_url
    if import_data && super.present?
      import_url = Gitlab::UrlSanitizer.new(super, credentials: import_data.credentials)
      import_url.full_url
    else
      super
    end
  end

  def valid_import_url?
    valid?(:import_url) || errors.messages[:import_url].nil?
  end

  def create_or_update_import_data(data: nil, credentials: nil)
    return unless import_url.present? && valid_import_url?

    project_import_data = import_data || build_import_data
    if data
      project_import_data.data ||= {}
      project_import_data.data = project_import_data.data.merge(data)
    end

    if credentials
      project_import_data.credentials ||= {}
      project_import_data.credentials = project_import_data.credentials.merge(credentials)
    end
  end

  def import?
    external_import? || forked? || gitlab_project_import? || bare_repository_import?
  end

  def no_import?
    import_status == 'none'
  end

  def external_import?
    import_url.present?
  end

  def imported?
    import_finished?
  end

  def import_in_progress?
    import_started? || import_scheduled?
  end

  def import_started?
    # import? does SQL work so only run it if it looks like there's an import running
    import_status == 'started' && import?
  end

  def import_scheduled?
    import_status == 'scheduled'
  end

  def import_failed?
    import_status == 'failed'
  end

  def import_finished?
    import_status == 'finished'
  end

  def safe_import_url
    Gitlab::UrlSanitizer.new(import_url).masked_url
  end

  def bare_repository_import?
    import_type == 'bare_repository'
  end

  def gitlab_project_import?
    import_type == 'gitlab_project'
  end

  def gitea_import?
    import_type == 'gitea'
  end

  def check_limit
    unless creator.can_create_project? || namespace.kind == 'group'
      projects_limit = creator.projects_limit

      if projects_limit == 0
        self.errors.add(:limit_reached, "Personal project creation is not allowed. Please contact your administrator with questions")
      else
        self.errors.add(:limit_reached, "Your project limit is #{projects_limit} projects! Please contact your administrator to increase it")
      end
    end
  rescue
    self.errors.add(:base, "Can't check your ability to create project")
  end

  def visibility_level_allowed_by_group
    return if visibility_level_allowed_by_group?

    level_name = Gitlab::VisibilityLevel.level_name(self.visibility_level).downcase
    group_level_name = Gitlab::VisibilityLevel.level_name(self.group.visibility_level).downcase
    self.errors.add(:visibility_level, "#{level_name} is not allowed in a #{group_level_name} group.")
  end

  def visibility_level_allowed_as_fork
    return if visibility_level_allowed_as_fork?

    level_name = Gitlab::VisibilityLevel.level_name(self.visibility_level).downcase
    self.errors.add(:visibility_level, "#{level_name} is not allowed since the fork source project has lower visibility.")
  end

  def check_wiki_path_conflict
    return if path.blank?

    path_to_check = path.ends_with?('.wiki') ? path.chomp('.wiki') : "#{path}.wiki"

    if Project.where(namespace_id: namespace_id, path: path_to_check).exists?
      errors.add(:name, 'has already been taken')
    end
  end

  def to_param
    if persisted? && errors.include?(:path)
      path_was
    else
      path
    end
  end

  # `from` argument can be a Namespace or Project.
  def to_reference(from = nil, full: false)
    if full || cross_namespace_reference?(from)
      full_path
    elsif cross_project_reference?(from)
      path
    end
  end

  def to_human_reference(from = nil)
    if cross_namespace_reference?(from)
      name_with_namespace
    elsif cross_project_reference?(from)
      name
    end
  end

  def web_url
    Gitlab::Routing.url_helpers.project_url(self)
  end

  def new_issuable_address(author, address_type)
    return unless Gitlab::IncomingEmail.supports_issue_creation? && author

    author.ensure_incoming_email_token!

    suffix = address_type == 'merge_request' ? '+merge-request' : ''
    Gitlab::IncomingEmail.reply_address(
      "#{full_path}#{suffix}+#{author.incoming_email_token}")
  end

  def build_commit_note(commit)
    notes.new(commit_id: commit.id, noteable_type: 'Commit')
  end

  def last_activity
    last_event
  end

  def last_activity_date
    [last_activity_at, last_repository_updated_at, updated_at].compact.max
  end

  def project_id
    self.id
  end

  def get_issue(issue_id, current_user)
    issue = IssuesFinder.new(current_user, project_id: id).find_by(iid: issue_id) if issues_enabled?

    if issue
      issue
    elsif external_issue_tracker
      ExternalIssue.new(issue_id, self)
    end
  end

  def issue_exists?(issue_id)
    get_issue(issue_id)
  end

  def default_issue_tracker
    gitlab_issue_tracker_service || create_gitlab_issue_tracker_service
  end

  def issues_tracker
    if external_issue_tracker
      external_issue_tracker
    else
      default_issue_tracker
    end
  end

  def external_issue_reference_pattern
    external_issue_tracker.class.reference_pattern(only_long: issues_enabled?)
  end

  def default_issues_tracker?
    !external_issue_tracker
  end

  def external_issue_tracker
    if has_external_issue_tracker.nil? # To populate existing projects
      cache_has_external_issue_tracker
    end

    if has_external_issue_tracker?
      return @external_issue_tracker if defined?(@external_issue_tracker)

      @external_issue_tracker = services.external_issue_trackers.first
    else
      nil
    end
  end

  def cache_has_external_issue_tracker
    update_column(:has_external_issue_tracker, services.external_issue_trackers.any?) if Gitlab::Database.read_write?
  end

  def has_wiki?
    wiki_enabled? || has_external_wiki?
  end

  def external_wiki
    if has_external_wiki.nil?
      cache_has_external_wiki # Populate
    end

    if has_external_wiki
      @external_wiki ||= services.external_wikis.first
    else
      nil
    end
  end

  def cache_has_external_wiki
    update_column(:has_external_wiki, services.external_wikis.any?) if Gitlab::Database.read_write?
  end

  def find_or_initialize_services(exceptions: [])
    services_templates = Service.where(template: true)

    available_services_names = Service.available_services_names - exceptions

    available_services_names.map do |service_name|
      service = find_service(services, service_name)

      if service
        service
      else
        # We should check if template for the service exists
        template = find_service(services_templates, service_name)

        if template.nil?
          # If no template, we should create an instance. Ex `build_gitlab_ci_service`
          public_send("build_#{service_name}_service") # rubocop:disable GitlabSecurity/PublicSend
        else
          Service.build_from_template(id, template)
        end
      end
    end
  end

  def find_or_initialize_service(name)
    find_or_initialize_services.find { |service| service.to_param == name }
  end

  def create_labels
    Label.templates.each do |label|
      params = label.attributes.except('id', 'template', 'created_at', 'updated_at')
      Labels::FindOrCreateService.new(nil, self, params).execute(skip_authorization: true)
    end
  end

  def find_service(list, name)
    list.find { |service| service.to_param == name }
  end

  def ci_services
    services.where(category: :ci)
  end

  def ci_service
    @ci_service ||= ci_services.reorder(nil).find_by(active: true)
  end

  def monitoring_services
    services.where(category: :monitoring)
  end

  def monitoring_service
    @monitoring_service ||= monitoring_services.reorder(nil).find_by(active: true)
  end

  def jira_tracker?
    issues_tracker.to_param == 'jira'
  end

  def avatar_in_git
    repository.avatar
  end

  def avatar_url(**args)
    Gitlab::Routing.url_helpers.project_avatar_url(self) if avatar_in_git
  end

  # For compatibility with old code
  def code
    path
  end

  def items_for(entity)
    case entity
    when 'issue' then
      issues
    when 'merge_request' then
      merge_requests
    end
  end

  def send_move_instructions(old_path_with_namespace)
    # New project path needs to be committed to the DB or notification will
    # retrieve stale information
    run_after_commit do
      NotificationService.new.project_was_moved(self, old_path_with_namespace)
    end
  end

  def owner
    if group
      group
    else
      namespace.try(:owner)
    end
  end

  def execute_hooks(data, hooks_scope = :push_hooks)
    run_after_commit_or_now do
      hooks.hooks_for(hooks_scope).each do |hook|
        hook.async_execute(data, hooks_scope.to_s)
      end

      SystemHooksService.new.execute_hooks(data, hooks_scope)
    end
  end

  def execute_services(data, hooks_scope = :push_hooks)
    # Call only service hooks that are active for this scope
    run_after_commit_or_now do
      services.public_send(hooks_scope).each do |service| # rubocop:disable GitlabSecurity/PublicSend
        service.async_execute(data)
      end
    end
  end

  def valid_repo?
    repository.exists?
  rescue
    errors.add(:path, 'Invalid repository path')
    false
  end

  def url_to_repo
    gitlab_shell.url_to_repo(full_path)
  end

  def repo_exists?
    strong_memoize(:repo_exists) do
      begin
        repository.exists?
      rescue
        false
      end
    end
  end

  def root_ref?(branch)
    repository.root_ref == branch
  end

  def ssh_url_to_repo
    url_to_repo
  end

  def http_url_to_repo
    "#{web_url}.git"
  end

  def user_can_push_to_empty_repo?(user)
    return false unless empty_repo?
    return false unless Ability.allowed?(user, :push_code, self)

    !ProtectedBranch.default_branch_protected? || team.max_member_access(user.id) > Gitlab::Access::DEVELOPER
  end

  def forked?
    return true if fork_network && fork_network.root_project != self

    # TODO: Use only the above conditional using the `fork_network`
    # This is the old conditional that looks at the `forked_project_link`, we
    # fall back to this while we're migrating the new models
    !(forked_project_link.nil? || forked_project_link.forked_from_project.nil?)
  end

  def fork_source
    return nil unless forked?

    forked_from_project || fork_network&.root_project
  end

  def lfs_storage_project
    @lfs_storage_project ||= begin
      result = self

      # TODO: Make this go to the fork_network root immeadiatly
      # dependant on the discussion in: https://gitlab.com/gitlab-org/gitlab-ce/issues/39769
      result = result.fork_source while result&.forked?

      result || self
    end
  end

  def personal?
    !group
  end

  # Expires various caches before a project is renamed.
  def expire_caches_before_rename(old_path)
    repo = Repository.new(old_path, self)
    wiki = Repository.new("#{old_path}.wiki", self)

    if repo.exists?
      repo.before_delete
    end

    if wiki.exists?
      wiki.before_delete
    end
  end

  # Check if repository already exists on disk
  def check_repository_path_availability
    return true if skip_disk_validation
    return false unless repository_storage_path

    expires_full_path_cache # we need to clear cache to validate renames correctly

    # Check if repository with same path already exists on disk we can
    # skip this for the hashed storage because the path does not change
    if legacy_storage? && repository_with_same_path_already_exists?
      errors.add(:base, 'There is already a repository with that name on disk')
      return false
    end

    true
  rescue GRPC::Internal # if the path is too long
    false
  end

  def create_repository(force: false)
    # Forked import is handled asynchronously
    return if forked? && !force

    if gitlab_shell.add_repository(repository_storage, disk_path)
      repository.after_create
      true
    else
      errors.add(:base, 'Failed to create repository via gitlab-shell')
      false
    end
  end

  def hook_attrs(backward: true)
    attrs = {
      id: id,
      name: name,
      description: description,
      web_url: web_url,
      avatar_url: avatar_url(only_path: false),
      git_ssh_url: ssh_url_to_repo,
      git_http_url: http_url_to_repo,
      namespace: namespace.name,
      visibility_level: visibility_level,
      path_with_namespace: full_path,
      default_branch: default_branch,
      ci_config_path: ci_config_path
    }

    # Backward compatibility
    if backward
      attrs.merge!({
                    homepage: web_url,
                    url: url_to_repo,
                    ssh_url: ssh_url_to_repo,
                    http_url: http_url_to_repo
                  })
    end

    attrs
  end

  def project_member(user)
    if project_members.loaded?
      project_members.find { |member| member.user_id == user.id }
    else
      project_members.find_by(user_id: user)
    end
  end

  def default_branch
    @default_branch ||= repository.root_ref if repository.exists?
  end

  def reload_default_branch
    @default_branch = nil
    default_branch
  end

  def visibility_level_field
    :visibility_level
  end

  def archive!
    update_attribute(:archived, true)
  end

  def unarchive!
    update_attribute(:archived, false)
  end

  def change_head(branch)
    if repository.branch_exists?(branch)
      repository.before_change_head
      repository.raw_repository.write_ref('HEAD', "refs/heads/#{branch}", shell: false)
      repository.copy_gitattributes(branch)
      repository.after_change_head
      reload_default_branch
    else
      errors.add(:base, "Could not change HEAD: branch '#{branch}' does not exist")
      false
    end
  end

  def forked_from?(other_project)
    forked? && forked_from_project == other_project
  end

  def in_fork_network_of?(other_project)
    # TODO: Remove this in a next release when all fork_networks are populated
    # This makes sure all MergeRequests remain valid while the projects don't
    # have a fork_network yet.
    return true if forked_from?(other_project)

    return false if fork_network.nil? || other_project.fork_network.nil?

    fork_network == other_project.fork_network
  end

  def origin_merge_requests
    merge_requests.where(source_project_id: self.id)
  end

  def ensure_repository
    create_repository(force: true) unless repository_exists?
  end

  def repository_exists?
    !!repository.exists?
  end

  def wiki_repository_exists?
    wiki.repository_exists?
  end

  # update visibility_level of forks
  def update_forks_visibility_level
    return unless visibility_level < visibility_level_was

    forks.each do |forked_project|
      if forked_project.visibility_level > visibility_level
        forked_project.visibility_level = visibility_level
        forked_project.save!
      end
    end
  end

  def create_wiki
    ProjectWiki.new(self, self.owner).wiki
    true
  rescue ProjectWiki::CouldNotCreateWikiError
    errors.add(:base, 'Failed create wiki')
    false
  end

  def wiki
    @wiki ||= ProjectWiki.new(self, self.owner)
  end

  def jira_tracker_active?
    jira_tracker? && jira_service.active
  end

  def allowed_to_share_with_group?
    !namespace.share_with_group_lock
  end

  def pipeline_for(ref, sha = nil)
    sha ||= commit(ref).try(:sha)

    return unless sha

    pipelines.order(id: :desc).find_by(sha: sha, ref: ref)
  end

  def latest_successful_pipeline_for_default_branch
    if defined?(@latest_successful_pipeline_for_default_branch)
      return @latest_successful_pipeline_for_default_branch
    end

    @latest_successful_pipeline_for_default_branch =
      pipelines.latest_successful_for(default_branch)
  end

  def latest_successful_pipeline_for(ref = nil)
    if ref && ref != default_branch
      pipelines.latest_successful_for(ref)
    else
      latest_successful_pipeline_for_default_branch
    end
  end

  def enable_ci
    project_feature.update_attribute(:builds_access_level, ProjectFeature::ENABLED)
  end

  def shared_runners_available?
    shared_runners_enabled?
  end

  def shared_runners
    @shared_runners ||= shared_runners_available? ? Ci::Runner.shared : Ci::Runner.none
  end

  def active_shared_runners
    @active_shared_runners ||= shared_runners.active
  end

  def any_runners?(&block)
    active_runners.any?(&block) || active_shared_runners.any?(&block)
  end

  def valid_runners_token?(token)
    self.runners_token && ActiveSupport::SecurityUtils.variable_size_secure_compare(token, self.runners_token)
  end

  def build_timeout_in_minutes
    build_timeout / 60
  end

  def build_timeout_in_minutes=(value)
    self.build_timeout = value.to_i * 60
  end

  def open_issues_count
    Projects::OpenIssuesCountService.new(self).count
  end

  def open_merge_requests_count
    Projects::OpenMergeRequestsCountService.new(self).count
  end

  def visibility_level_allowed_as_fork?(level = self.visibility_level)
    return true unless forked?

    # self.forked_from_project will be nil before the project is saved, so
    # we need to go through the relation
    original_project = forked_project_link&.forked_from_project
    return true unless original_project

    level <= original_project.visibility_level
  end

  def visibility_level_allowed_by_group?(level = self.visibility_level)
    return true unless group

    level <= group.visibility_level
  end

  def visibility_level_allowed?(level = self.visibility_level)
    visibility_level_allowed_as_fork?(level) && visibility_level_allowed_by_group?(level)
  end

  def runners_token
    ensure_runners_token!
  end

  def pages_deployed?
    Dir.exist?(public_pages_path)
  end

  def pages_url
    subdomain, _, url_path = full_path.partition('/')

    # The hostname always needs to be in downcased
    # All web servers convert hostname to lowercase
    host = "#{subdomain}.#{Settings.pages.host}".downcase

    # The host in URL always needs to be downcased
    url = Gitlab.config.pages.url.sub(%r{^https?://}) do |prefix|
      "#{prefix}#{subdomain}."
    end.downcase

    # If the project path is the same as host, we serve it as group page
    return url if host == url_path

    "#{url}/#{url_path}"
  end

  def pages_subdomain
    full_path.partition('/').first
  end

  def pages_path
    # TODO: when we migrate Pages to work with new storage types, change here to use disk_path
    File.join(Settings.pages.path, full_path)
  end

  def public_pages_path
    File.join(pages_path, 'public')
  end

  def pages_available?
    Gitlab.config.pages.enabled && !namespace.subgroup?
  end

  def remove_private_deploy_keys
    exclude_keys_linked_to_other_projects = <<-SQL
      NOT EXISTS (
        SELECT 1
        FROM deploy_keys_projects dkp2
        WHERE dkp2.deploy_key_id = deploy_keys_projects.deploy_key_id
        AND dkp2.project_id != deploy_keys_projects.project_id
      )
    SQL

    deploy_keys.where(public: false)
               .where(exclude_keys_linked_to_other_projects)
               .delete_all
  end

  # TODO: what to do here when not using Legacy Storage? Do we still need to rename and delay removal?
  def remove_pages
    # Projects with a missing namespace cannot have their pages removed
    return unless namespace

    ::Projects::UpdatePagesConfigurationService.new(self).execute

    # 1. We rename pages to temporary directory
    # 2. We wait 5 minutes, due to NFS caching
    # 3. We asynchronously remove pages with force
    temp_path = "#{path}.#{SecureRandom.hex}.deleted"

    if Gitlab::PagesTransfer.new.rename_project(path, temp_path, namespace.full_path)
      PagesWorker.perform_in(5.minutes, :remove, namespace.full_path, temp_path)
    end
  end

  def rename_repo
    new_full_path = build_full_path

    Rails.logger.error "Attempting to rename #{full_path_was} -> #{new_full_path}"

    if has_container_registry_tags?
      Rails.logger.error "Project #{full_path_was} cannot be renamed because container registry tags are present!"

      # we currently doesn't support renaming repository if it contains images in container registry
      raise StandardError.new('Project cannot be renamed, because images are present in its container registry')
    end

    expire_caches_before_rename(full_path_was)

    if storage.rename_repo
      Gitlab::AppLogger.info "Project was renamed: #{full_path_was} -> #{new_full_path}"
      rename_repo_notify!
      after_rename_repo
    else
      Rails.logger.error "Repository could not be renamed: #{full_path_was} -> #{new_full_path}"

      # if we cannot move namespace directory we should rollback
      # db changes in order to prevent out of sync between db and fs
      raise StandardError.new('repository cannot be renamed')
    end
  end

  def after_rename_repo
    write_repository_config

    path_before_change = previous_changes['path'].first

    # We need to check if project had been rolled out to move resource to hashed storage or not and decide
    # if we need execute any take action or no-op.

    unless hashed_storage?(:attachments)
      Gitlab::UploadsTransfer.new.rename_project(path_before_change, self.path, namespace.full_path)
    end

    Gitlab::PagesTransfer.new.rename_project(path_before_change, self.path, namespace.full_path)
  end

  def write_repository_config(gl_full_path: full_path)
    # We'd need to keep track of project full path otherwise directory tree
    # created with hashed storage enabled cannot be usefully imported using
    # the import rake task.
    repository.raw_repository.write_config(full_path: gl_full_path)
  rescue Gitlab::Git::Repository::NoRepository => e
    Rails.logger.error("Error writing to .git/config for project #{full_path} (#{id}): #{e.message}.")
    nil
  end

  def rename_repo_notify!
    send_move_instructions(full_path_was)
    expires_full_path_cache

    self.old_path_with_namespace = full_path_was
    SystemHooksService.new.execute_hooks_for(self, :rename)

    reload_repository!
  end

  def after_import
    repository.after_import
    import_finish
    remove_import_jid
    update_project_counter_caches
    after_create_default_branch
  end

  def update_project_counter_caches
    classes = [
      Projects::OpenIssuesCountService,
      Projects::OpenMergeRequestsCountService
    ]

    classes.each do |klass|
      klass.new(self).refresh_cache
    end
  end

  def after_create_default_branch
    return unless default_branch

    # Ensure HEAD points to the default branch in case it is not master
    change_head(default_branch)

    if Gitlab::CurrentSettings.default_branch_protection != Gitlab::Access::PROTECTION_NONE && !ProtectedBranch.protected?(self, default_branch)
      params = {
        name: default_branch,
        push_access_levels_attributes: [{
          access_level: Gitlab::CurrentSettings.default_branch_protection == Gitlab::Access::PROTECTION_DEV_CAN_PUSH ? Gitlab::Access::DEVELOPER : Gitlab::Access::MASTER
        }],
        merge_access_levels_attributes: [{
          access_level: Gitlab::CurrentSettings.default_branch_protection == Gitlab::Access::PROTECTION_DEV_CAN_MERGE ? Gitlab::Access::DEVELOPER : Gitlab::Access::MASTER
        }]
      }

      ProtectedBranches::CreateService.new(self, creator, params).execute(skip_authorization: true)
    end
  end

  def remove_import_jid
    return unless import_jid

    Gitlab::SidekiqStatus.unset(import_jid)
    update_column(:import_jid, nil)
  end

  def running_or_pending_build_count(force: false)
    Rails.cache.fetch(['projects', id, 'running_or_pending_build_count'], force: force) do
      builds.running_or_pending.count(:all)
    end
  end

  # Lazy loading of the `pipeline_status` attribute
  def pipeline_status
    @pipeline_status ||= Gitlab::Cache::Ci::ProjectPipelineStatus.load_for_project(self)
  end

  def mark_import_as_failed(error_message)
    original_errors = errors.dup
    sanitized_message = Gitlab::UrlSanitizer.sanitize(error_message)

    import_fail
    update_column(:import_error, sanitized_message)
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("Error setting import status to failed: #{e.message}. Original error: #{sanitized_message}")
  ensure
    @errors = original_errors
  end

  def add_export_job(current_user:)
    job_id = ProjectExportWorker.perform_async(current_user.id, self.id)

    if job_id
      Rails.logger.info "Export job started for project ID #{self.id} with job ID #{job_id}"
    else
      Rails.logger.error "Export job failed to start for project ID #{self.id}"
    end
  end

  def import_export_shared
    @import_export_shared ||= Gitlab::ImportExport::Shared.new(self)
  end

  def export_path
    return nil unless namespace.present? || hashed_storage?(:repository)

    import_export_shared.archive_path
  end

  def export_project_path
    Dir.glob("#{export_path}/*export.tar.gz").max_by { |f| File.ctime(f) }
  end

  def export_status
    if export_in_progress?
      :started
    elsif export_project_path
      :finished
    else
      :none
    end
  end

  def export_in_progress?
    import_export_shared.active_export_count > 0
  end

  def remove_exports
    return nil unless export_path.present?

    FileUtils.rm_rf(export_path)
  end

  def full_path_slug
    Gitlab::Utils.slugify(full_path.to_s)
  end

  def has_ci?
    repository.gitlab_ci_yml || auto_devops_enabled?
  end

  def predefined_variables
    [
      { key: 'CI_PROJECT_ID', value: id.to_s, public: true },
      { key: 'CI_PROJECT_NAME', value: path, public: true },
      { key: 'CI_PROJECT_PATH', value: full_path, public: true },
      { key: 'CI_PROJECT_PATH_SLUG', value: full_path_slug, public: true },
      { key: 'CI_PROJECT_NAMESPACE', value: namespace.full_path, public: true },
      { key: 'CI_PROJECT_URL', value: web_url, public: true },
      { key: 'CI_PROJECT_VISIBILITY', value: Gitlab::VisibilityLevel.string_level(visibility_level), public: true }
    ]
  end

  def container_registry_variables
    return [] unless Gitlab.config.registry.enabled

    variables = [
      { key: 'CI_REGISTRY', value: Gitlab.config.registry.host_port, public: true }
    ]

    if container_registry_enabled?
      variables << { key: 'CI_REGISTRY_IMAGE', value: container_registry_url, public: true }
    end

    variables
  end

  def secret_variables_for(ref:, environment: nil)
    # EE would use the environment
    if protected_for?(ref)
      variables
    else
      variables.unprotected
    end
  end

  def protected_for?(ref)
    if repository.branch_exists?(ref)
      ProtectedBranch.protected?(self, ref)
    elsif repository.tag_exists?(ref)
      ProtectedTag.protected?(self, ref)
    end
  end

  def deployment_variables
    return [] unless deployment_platform

    deployment_platform.predefined_variables
  end

  def auto_devops_variables
    return [] unless auto_devops_enabled?

    (auto_devops || build_auto_devops)&.variables
  end

  def append_or_update_attribute(name, value)
    old_values = public_send(name.to_s) # rubocop:disable GitlabSecurity/PublicSend

    if Project.reflect_on_association(name).try(:macro) == :has_many && old_values.any?
      update_attribute(name, old_values + value)
    else
      update_attribute(name, value)
    end

  rescue ActiveRecord::RecordNotSaved => e
    handle_update_attribute_error(e, value)
  end

  def pushes_since_gc
    Gitlab::Redis::SharedState.with { |redis| redis.get(pushes_since_gc_redis_shared_state_key).to_i }
  end

  def increment_pushes_since_gc
    Gitlab::Redis::SharedState.with { |redis| redis.incr(pushes_since_gc_redis_shared_state_key) }
  end

  def reset_pushes_since_gc
    Gitlab::Redis::SharedState.with { |redis| redis.del(pushes_since_gc_redis_shared_state_key) }
  end

  def route_map_for(commit_sha)
    @route_maps_by_commit ||= Hash.new do |h, sha|
      h[sha] = begin
        data = repository.route_map_for(sha)
        next unless data

        Gitlab::RouteMap.new(data)
      rescue Gitlab::RouteMap::FormatError
        nil
      end
    end

    @route_maps_by_commit[commit_sha]
  end

  def public_path_for_source_path(path, commit_sha)
    map = route_map_for(commit_sha)
    return unless map

    map.public_path_for_source_path(path)
  end

  def parent_changed?
    namespace_id_changed?
  end

  def default_merge_request_target
    if forked_from_project&.merge_requests_enabled?
      forked_from_project
    else
      self
    end
  end

  # Overridden on EE module
  def multiple_issue_boards_available?
    false
  end

  def issue_board_milestone_available?(user = nil)
    feature_available?(:issue_board_milestone, user)
  end

  def full_path_was
    File.join(namespace.full_path, previous_changes['path'].first)
  end

  alias_method :name_with_namespace, :full_name
  alias_method :human_name, :full_name
  # @deprecated cannot remove yet because it has an index with its name in elasticsearch
  alias_method :path_with_namespace, :full_path

  def forks_count
    Projects::ForksCountService.new(self).count
  end

  def legacy_storage?
    [nil, 0].include?(self.storage_version)
  end

  # Check if Hashed Storage is enabled for the project with at least informed feature rolled out
  #
  # @param [Symbol] feature that needs to be rolled out for the project (:repository, :attachments)
  def hashed_storage?(feature)
    raise ArgumentError, "Invalid feature" unless HASHED_STORAGE_FEATURES.include?(feature)

    self.storage_version && self.storage_version >= HASHED_STORAGE_FEATURES[feature]
  end

  def renamed?
    persisted? && path_changed?
  end

  def merge_method
    if self.merge_requests_ff_only_enabled
      :ff
    elsif self.merge_requests_rebase_enabled
      :rebase_merge
    else
      :merge
    end
  end

  def merge_method=(method)
    case method.to_s
    when "ff"
      self.merge_requests_ff_only_enabled = true
      self.merge_requests_rebase_enabled = true
    when "rebase_merge"
      self.merge_requests_ff_only_enabled = false
      self.merge_requests_rebase_enabled = true
    when "merge"
      self.merge_requests_ff_only_enabled = false
      self.merge_requests_rebase_enabled = false
    end
  end

  def ff_merge_must_be_possible?
    self.merge_requests_ff_only_enabled || self.merge_requests_rebase_enabled
  end

  def migrate_to_hashed_storage!
    return if hashed_storage?(:repository)

    update!(repository_read_only: true)

    if repo_reference_count > 0 || wiki_reference_count > 0
      ProjectMigrateHashedStorageWorker.perform_in(Gitlab::ReferenceCounter::REFERENCE_EXPIRE_TIME, id)
    else
      ProjectMigrateHashedStorageWorker.perform_async(id)
    end
  end

  def storage_version=(value)
    super

    @storage = nil if storage_version_changed?
  end

  def gl_repository(is_wiki:)
    Gitlab::GlRepository.gl_repository(self, is_wiki)
  end

  def reference_counter(wiki: false)
    Gitlab::ReferenceCounter.new(gl_repository(is_wiki: wiki))
  end

  # Refreshes the expiration time of the associated import job ID.
  #
  # This method can be used by asynchronous importers to refresh the status,
  # preventing the StuckImportJobsWorker from marking the import as failed.
  def refresh_import_jid_expiration
    return unless import_jid

    Gitlab::SidekiqStatus
      .set(import_jid, StuckImportJobsWorker::IMPORT_JOBS_EXPIRATION)
  end

  def badges
    return project_badges unless group

    group_badges_rel = GroupBadge.where(group: group.self_and_ancestors)

    union = Gitlab::SQL::Union.new([project_badges.select(:id),
                                    group_badges_rel.select(:id)])

    Badge.where("id IN (#{union.to_sql})") # rubocop:disable GitlabSecurity/SqlInjection
  end

  def merge_requests_allowing_push_to_user(user)
    return MergeRequest.none unless user

    developer_access_exists = user.project_authorizations
                                .where('access_level >= ? ', Gitlab::Access::DEVELOPER)
                                .where('project_authorizations.project_id = merge_requests.target_project_id')
                                .limit(1)
                                .select(1)
    source_of_merge_requests.opened
      .where(allow_maintainer_to_push: true)
      .where('EXISTS (?)', developer_access_exists)
  end

  def branch_allows_maintainer_push?(user, branch_name)
    return false unless user

    cache_key = "user:#{user.id}:#{branch_name}:branch_allows_push"

    memoized_results = strong_memoize(:branch_allows_maintainer_push) do
      Hash.new do |result, cache_key|
        result[cache_key] = fetch_branch_allows_maintainer_push?(user, branch_name)
      end
    end

    memoized_results[cache_key]
  end

  private

  def storage
    @storage ||=
      if hashed_storage?(:repository)
        Storage::HashedProject.new(self)
      else
        Storage::LegacyProject.new(self)
      end
  end

  def use_hashed_storage
    if self.new_record? && Gitlab::CurrentSettings.hashed_storage_enabled
      self.storage_version = LATEST_STORAGE_VERSION
    end
  end

  def repo_reference_count
    reference_counter.value
  end

  def wiki_reference_count
    reference_counter(wiki: true).value
  end

  def check_repository_absence!
    return if skip_disk_validation

    if repository_storage_path.blank? || repository_with_same_path_already_exists?
      errors.add(:base, 'There is already a repository with that name on disk')
      throw :abort
    end
  end

  def repository_with_same_path_already_exists?
    gitlab_shell.exists?(repository_storage_path, "#{disk_path}.git")
  end

  # set last_activity_at to the same as created_at
  def set_last_activity_at
    update_column(:last_activity_at, self.created_at)
  end

  def set_last_repository_updated_at
    update_column(:last_repository_updated_at, self.created_at)
  end

  def cross_namespace_reference?(from)
    case from
    when Project
      namespace != from.namespace
    when Namespace
      namespace != from
    end
  end

  # Check if a reference is being done cross-project
  def cross_project_reference?(from)
    return true if from.is_a?(Namespace)

    from && self != from
  end

  def pushes_since_gc_redis_shared_state_key
    "projects/#{id}/pushes_since_gc"
  end

  # Similar to the normal callbacks that hook into the life cycle of an
  # Active Record object, you can also define callbacks that get triggered
  # when you add an object to an association collection. If any of these
  # callbacks throw an exception, the object will not be added to the
  # collection. Before you add a new board to the boards collection if you
  # already have 1, 2, or n it will fail, but it if you have 0 that is lower
  # than the number of permitted boards per project it won't fail.
  def validate_board_limit(board)
    raise BoardLimitExceeded, 'Number of permitted boards exceeded' if boards.size >= NUMBER_OF_PERMITTED_BOARDS
  end

  def update_project_statistics
    stats = statistics || build_statistics
    stats.update(namespace_id: namespace_id)
  end

  def check_pending_delete
    return if valid_attribute?(:name) && valid_attribute?(:path)
    return unless pending_delete_twin

    %i[route route.path name path].each do |error|
      errors.delete(error)
    end

    errors.add(:base, "The project is still being deleted. Please try again later.")
  end

  def pending_delete_twin
    return false unless path

    Project.pending_delete.find_by_full_path(full_path)
  end

  ##
  # This method is here because of support for legacy container repository
  # which has exactly the same path like project does, but which might not be
  # persisted in `container_repositories` table.
  #
  def has_root_container_repository_tags?
    return false unless Gitlab.config.registry.enabled

    ContainerRepository.build_root_repository(self).has_tags?
  end

  def handle_update_attribute_error(ex, value)
    if ex.message.start_with?('Failed to replace')
      if value.respond_to?(:each)
        invalid = value.detect(&:invalid?)

        raise ex, ([ex.message] + invalid.errors.full_messages).join(' ') if invalid
      end
    end

    raise ex
  end

  def fetch_branch_allows_maintainer_push?(user, branch_name)
    check_access = -> do
      merge_request = source_of_merge_requests.opened
                        .where(allow_maintainer_to_push: true)
                        .find_by(source_branch: branch_name)

      merge_request&.can_be_merged_by?(user)
    end

    if RequestStore.active?
      RequestStore.fetch("project-#{id}:branch-#{branch_name}:user-#{user.id}:branch_allows_maintainer_push") do
        check_access.call
      end
    else
      check_access.call
    end
  end
end
