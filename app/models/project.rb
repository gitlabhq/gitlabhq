# frozen_string_literal: true

require 'carrierwave/orm/activerecord'

class Project < ApplicationRecord
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
  include ProjectAPICompatibility
  include ProjectFeaturesCompatibility
  include SelectForProjectAuthorization
  include Presentable
  include Routable
  include GroupDescendant
  include Gitlab::SQL::Pattern
  include DeploymentPlatform
  include ::Gitlab::Utils::StrongMemoize
  include ChronicDurationAttribute
  include FastDestroyAll::Helpers
  include WithUploads
  include BatchDestroyDependentAssociations
  include FeatureGate
  include OptionallySearch
  include FromUnion
  include IgnorableColumns
  extend Gitlab::Cache::RequestCache

  extend Gitlab::ConfigHelper

  BoardLimitExceeded = Class.new(StandardError)

  STATISTICS_ATTRIBUTE = 'repositories_count'
  UNKNOWN_IMPORT_URL = 'http://unknown.git'
  # Hashed Storage versions handle rolling out new storage to project and dependents models:
  # nil: legacy
  # 1: repository
  # 2: attachments
  LATEST_STORAGE_VERSION = 2
  HASHED_STORAGE_FEATURES = {
    repository: 1,
    attachments: 2
  }.freeze

  VALID_IMPORT_PORTS = [80, 443].freeze
  VALID_IMPORT_PROTOCOLS = %w(http https git).freeze

  VALID_MIRROR_PORTS = [22, 80, 443].freeze
  VALID_MIRROR_PROTOCOLS = %w(http https ssh git).freeze

  ACCESS_REQUEST_APPROVERS_TO_BE_NOTIFIED_LIMIT = 10

  SORTING_PREFERENCE_FIELD = :projects_sort
  MAX_BUILD_TIMEOUT = 1.month

  cache_markdown_field :description, pipeline: :description

  # TODO: remove once GitLab 12.5 is released
  # https://gitlab.com/gitlab-org/gitlab/issues/34638
  ignore_column :merge_requests_require_code_owner_approval, remove_after: '2019-12-01', remove_with: '12.6'

  default_value_for :archived, false
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
  default_value_for :remove_source_branch_after_merge, true
  default_value_for(:ci_config_path) { Gitlab::CurrentSettings.default_ci_config_path }

  add_authentication_token_field :runners_token, encrypted: -> { Feature.enabled?(:projects_tokens_optional_encryption, default_enabled: true) ? :optional : :required }

  before_validation :mark_remote_mirrors_for_removal, if: -> { RemoteMirror.table_exists? }

  before_save :ensure_runners_token

  after_save :update_project_statistics, if: :saved_change_to_namespace_id?

  after_save :create_import_state, if: ->(project) { project.import? && project.import_state.nil? }

  after_create :create_project_feature, unless: :project_feature

  after_create :create_ci_cd_settings,
    unless: :ci_cd_settings,
    if: proc { ProjectCiCdSetting.available? }

  after_create :create_container_expiration_policy,
               unless: :container_expiration_policy

  after_create :create_pages_metadatum,
               unless: :pages_metadatum

  after_create :set_timestamps_for_create
  after_update :update_forks_visibility_level

  before_destroy :remove_private_deploy_keys

  use_fast_destroy :build_trace_chunks

  after_destroy -> { run_after_commit { remove_pages } }
  after_destroy :remove_exports

  after_validation :check_pending_delete

  # Storage specific hooks
  after_initialize :use_hashed_storage
  after_create :check_repository_absence!

  acts_as_ordered_taggable

  attr_accessor :old_path_with_namespace
  attr_accessor :template_name
  attr_writer :pipeline_status
  attr_accessor :skip_disk_validation

  alias_attribute :title, :name

  # Relations
  belongs_to :pool_repository
  belongs_to :creator, class_name: 'User'
  belongs_to :group, -> { where(type: 'Group') }, foreign_key: 'namespace_id'
  belongs_to :namespace
  alias_method :parent, :namespace
  alias_attribute :parent_id, :namespace_id

  has_one :last_event, -> {order 'events.created_at DESC'}, class_name: 'Event'
  has_many :boards

  # Project services
  has_one :campfire_service
  has_one :discord_service
  has_one :drone_ci_service
  has_one :emails_on_push_service
  has_one :pipelines_email_service
  has_one :irker_service
  has_one :pivotaltracker_service
  has_one :hipchat_service
  has_one :flowdock_service
  has_one :assembla_service
  has_one :asana_service
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
  has_one :youtrack_service
  has_one :custom_issue_tracker_service
  has_one :bugzilla_service
  has_one :gitlab_issue_tracker_service, inverse_of: :project
  has_one :external_wiki_service
  has_one :prometheus_service, inverse_of: :project
  has_one :mock_ci_service
  has_one :mock_deployment_service
  has_one :mock_monitoring_service
  has_one :microsoft_teams_service
  has_one :packagist_service
  has_one :hangouts_chat_service
  has_one :unify_circuit_service

  has_one :root_of_fork_network,
          foreign_key: 'root_project_id',
          inverse_of: :root_project,
          class_name: 'ForkNetwork'
  has_one :fork_network_member
  has_one :fork_network, through: :fork_network_member
  has_one :forked_from_project, through: :fork_network_member
  has_many :forked_to_members, class_name: 'ForkNetworkMember', foreign_key: 'forked_from_project_id'
  has_many :forks, through: :forked_to_members, source: :project, inverse_of: :forked_from_project
  has_many :fork_network_projects, through: :fork_network, source: :projects

  has_one :import_state, autosave: true, class_name: 'ProjectImportState', inverse_of: :project
  has_one :import_export_upload, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_one :project_repository, inverse_of: :project
  has_one :error_tracking_setting, inverse_of: :project, class_name: 'ErrorTracking::ProjectErrorTrackingSetting'
  has_one :metrics_setting, inverse_of: :project, class_name: 'ProjectMetricsSetting'
  has_one :grafana_integration, inverse_of: :project

  # Merge Requests for target project should be removed with it
  has_many :merge_requests, foreign_key: 'target_project_id', inverse_of: :target_project
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
  has_many :repository_languages, -> { order "share DESC" }

  has_many :project_authorizations
  has_many :authorized_users, through: :project_authorizations, source: :user, class_name: 'User'
  has_many :project_members, -> { where(requested_at: nil) },
    as: :source, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  alias_method :members, :project_members
  has_many :users, through: :project_members

  has_many :requesters, -> { where.not(requested_at: nil) },
    as: :source, class_name: 'ProjectMember', dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
  has_many :members_and_requesters, as: :source, class_name: 'ProjectMember'

  has_many :deploy_keys_projects, inverse_of: :project
  has_many :deploy_keys, through: :deploy_keys_projects
  has_many :users_star_projects
  has_many :starrers, through: :users_star_projects, source: :user
  has_many :releases
  has_many :lfs_objects_projects, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :lfs_objects, -> { distinct }, through: :lfs_objects_projects
  has_many :lfs_file_locks
  has_many :project_group_links
  has_many :invited_groups, through: :project_group_links, source: :group
  has_many :pages_domains
  has_many :todos
  has_many :notification_settings, as: :source, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  has_many :internal_ids

  has_one :import_data, class_name: 'ProjectImportData', inverse_of: :project, autosave: true
  has_one :project_feature, inverse_of: :project
  has_one :statistics, class_name: 'ProjectStatistics'

  has_one :cluster_project, class_name: 'Clusters::Project'
  has_many :clusters, through: :cluster_project, class_name: 'Clusters::Cluster'
  has_many :kubernetes_namespaces, class_name: 'Clusters::KubernetesNamespace'
  has_many :management_clusters, class_name: 'Clusters::Cluster', foreign_key: :management_project_id, inverse_of: :management_project

  has_many :prometheus_metrics

  # Container repositories need to remove data from the container registry,
  # which is not managed by the DB. Hence we're still using dependent: :destroy
  # here.
  has_many :container_repositories, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_one :container_expiration_policy, inverse_of: :project

  has_many :commit_statuses
  # The relation :all_pipelines is intended to be used when we want to get the
  # whole list of pipelines associated to the project
  has_many :all_pipelines, class_name: 'Ci::Pipeline', inverse_of: :project
  # The relation :ci_pipelines is intended to be used when we want to get only
  # those pipeline which are directly related to CI. There are
  # other pipelines, like webide ones, that we won't retrieve
  # if we use this relation.
  has_many :ci_pipelines,
          -> { ci_sources },
          class_name: 'Ci::Pipeline',
          inverse_of: :project
  has_many :stages, class_name: 'Ci::Stage', inverse_of: :project

  # Ci::Build objects store data on the file system such as artifact files and
  # build traces. Currently there's no efficient way of removing this data in
  # bulk that doesn't involve loading the rows into memory. As a result we're
  # still using `dependent: :destroy` here.
  has_many :builds, class_name: 'Ci::Build', inverse_of: :project, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :build_trace_section_names, class_name: 'Ci::BuildTraceSectionName'
  has_many :build_trace_chunks, class_name: 'Ci::BuildTraceChunk', through: :builds, source: :trace_chunks
  has_many :job_artifacts, class_name: 'Ci::JobArtifact'
  has_many :runner_projects, class_name: 'Ci::RunnerProject', inverse_of: :project
  has_many :runners, through: :runner_projects, source: :runner, class_name: 'Ci::Runner'
  has_many :variables, class_name: 'Ci::Variable'
  has_many :triggers, class_name: 'Ci::Trigger'
  has_many :environments
  has_many :environments_for_dashboard, -> { from(with_rank.unfoldered.available, :environments).where('rank <= 3') }, class_name: 'Environment'
  has_many :deployments
  has_many :pipeline_schedules, class_name: 'Ci::PipelineSchedule'
  has_many :project_deploy_tokens
  has_many :deploy_tokens, through: :project_deploy_tokens
  has_many :resource_groups, class_name: 'Ci::ResourceGroup', inverse_of: :project

  has_one :auto_devops, class_name: 'ProjectAutoDevops', inverse_of: :project, autosave: true
  has_many :custom_attributes, class_name: 'ProjectCustomAttribute'

  has_many :project_badges, class_name: 'ProjectBadge'
  has_one :ci_cd_settings, class_name: 'ProjectCiCdSetting', inverse_of: :project, autosave: true, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  has_many :remote_mirrors, inverse_of: :project
  has_many :cycle_analytics_stages, class_name: 'Analytics::CycleAnalytics::ProjectStage'

  has_many :external_pull_requests, inverse_of: :project

  has_many :sourced_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :source_project_id
  has_many :source_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :project_id

  has_one :pages_metadatum, class_name: 'ProjectPagesMetadatum', inverse_of: :project

  has_many :import_failures, inverse_of: :project

  accepts_nested_attributes_for :variables, allow_destroy: true
  accepts_nested_attributes_for :project_feature, update_only: true
  accepts_nested_attributes_for :import_data
  accepts_nested_attributes_for :auto_devops, update_only: true
  accepts_nested_attributes_for :ci_cd_settings, update_only: true
  accepts_nested_attributes_for :container_expiration_policy, update_only: true

  accepts_nested_attributes_for :remote_mirrors,
                                allow_destroy: true,
                                reject_if: ->(attrs) { attrs[:id].blank? && attrs[:url].blank? }

  accepts_nested_attributes_for :error_tracking_setting, update_only: true
  accepts_nested_attributes_for :metrics_setting, update_only: true, allow_destroy: true
  accepts_nested_attributes_for :grafana_integration, update_only: true, allow_destroy: true

  delegate :feature_available?, :builds_enabled?, :wiki_enabled?, :merge_requests_enabled?,
    :issues_enabled?, :pages_enabled?, :public_pages?, :private_pages?,
    :merge_requests_access_level, :issues_access_level, :wiki_access_level,
    :snippets_access_level, :builds_access_level, :repository_access_level,
    to: :project_feature, allow_nil: true
  delegate :scheduled?, :started?, :in_progress?, :failed?, :finished?,
    prefix: :import, to: :import_state, allow_nil: true
  delegate :base_dir, :disk_path, to: :storage
  delegate :no_import?, to: :import_state, allow_nil: true
  delegate :name, to: :owner, allow_nil: true, prefix: true
  delegate :members, to: :team, prefix: true
  delegate :add_user, :add_users, to: :team
  delegate :add_guest, :add_reporter, :add_developer, :add_maintainer, :add_role, to: :team
  delegate :add_master, to: :team # @deprecated
  delegate :group_runners_enabled, :group_runners_enabled=, :group_runners_enabled?, to: :ci_cd_settings
  delegate :root_ancestor, :actual_limits, to: :namespace, allow_nil: true
  delegate :last_pipeline, to: :commit, allow_nil: true
  delegate :external_dashboard_url, to: :metrics_setting, allow_nil: true, prefix: true
  delegate :default_git_depth, :default_git_depth=, to: :ci_cd_settings, prefix: :ci

  # Validations
  validates :creator, presence: true, on: :create
  validates :description, length: { maximum: 2000 }, allow_blank: true
  validates :ci_config_path,
    format: { without: %r{(\.{2}|\A/)},
              message: _('cannot include leading slash or directory traversal.') },
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
  validates :import_url, public_url: { schemes: ->(project) { project.persisted? ? VALID_MIRROR_PROTOCOLS : VALID_IMPORT_PROTOCOLS },
                                       ports: ->(project) { project.persisted? ? VALID_MIRROR_PORTS : VALID_IMPORT_PORTS },
                                       enforce_user: true }, if: [:external_import?, :import_url_changed?]
  validates :star_count, numericality: { greater_than_or_equal_to: 0 }
  validate :check_personal_projects_limit, on: :create
  validate :check_repository_path_availability, on: :update, if: ->(project) { project.renamed? }
  validate :visibility_level_allowed_by_group, if: :should_validate_visibility_level?
  validate :visibility_level_allowed_as_fork, if: :should_validate_visibility_level?
  validate :check_wiki_path_conflict
  validate :validate_pages_https_only, if: -> { changes.has_key?(:pages_https_only) }
  validates :repository_storage,
    presence: true,
    inclusion: { in: ->(_object) { Gitlab.config.repositories.storages.keys } }
  validates :variables, variable_duplicates: { scope: :environment_scope }
  validates :bfg_object_map, file_size: { maximum: :max_attachment_size }
  validates :max_artifacts_size, numericality: { only_integer: true, greater_than: 0, allow_nil: true }

  # Scopes
  scope :pending_delete, -> { where(pending_delete: true) }
  scope :without_deleted, -> { where(pending_delete: false) }

  scope :with_storage_feature, ->(feature) do
    where(arel_table[:storage_version].gteq(HASHED_STORAGE_FEATURES[feature]))
  end
  scope :without_storage_feature, ->(feature) do
    where(arel_table[:storage_version].lt(HASHED_STORAGE_FEATURES[feature])
        .or(arel_table[:storage_version].eq(nil)))
  end
  scope :with_unmigrated_storage, -> do
    where(arel_table[:storage_version].lt(LATEST_STORAGE_VERSION)
        .or(arel_table[:storage_version].eq(nil)))
  end

  # last_activity_at is throttled every minute, but last_repository_updated_at is updated with every push
  scope :sorted_by_activity, -> { reorder(Arel.sql("GREATEST(COALESCE(last_activity_at, '1970-01-01'), COALESCE(last_repository_updated_at, '1970-01-01')) DESC")) }
  scope :sorted_by_stars_desc, -> { reorder(star_count: :desc) }
  scope :sorted_by_stars_asc, -> { reorder(star_count: :asc) }
  scope :sorted_by_name_asc_limited, ->(limit) { reorder(name: :asc).limit(limit) }

  scope :in_namespace, ->(namespace_ids) { where(namespace_id: namespace_ids) }
  scope :personal, ->(user) { where(namespace_id: user.namespace_id) }
  scope :joined, ->(user) { where('namespace_id != ?', user.namespace_id) }
  scope :starred_by, ->(user) { joins(:users_star_projects).where('users_star_projects.user_id': user.id) }
  scope :visible_to_user, ->(user) { where(id: user.authorized_projects.select(:id).reorder(nil)) }
  scope :visible_to_user_and_access_level, ->(user, access_level) { where(id: user.authorized_projects.where('project_authorizations.access_level >= ?', access_level).select(:id).reorder(nil)) }
  scope :archived, -> { where(archived: true) }
  scope :non_archived, -> { where(archived: false) }
  scope :for_milestones, ->(ids) { joins(:milestones).where('milestones.id' => ids).distinct }
  scope :with_push, -> { joins(:events).where('events.action = ?', Event::PUSHED) }
  scope :with_project_feature, -> { joins('LEFT JOIN project_features ON projects.id = project_features.project_id') }
  scope :inc_routes, -> { includes(:route, namespace: :route) }
  scope :with_statistics, -> { includes(:statistics) }
  scope :with_service, ->(service) { joins(service).eager_load(service) }
  scope :with_shared_runners, -> { where(shared_runners_enabled: true) }
  scope :with_container_registry, -> { where(container_registry_enabled: true) }
  scope :inside_path, ->(path) do
    # We need routes alias rs for JOIN so it does not conflict with
    # includes(:route) which we use in ProjectsFinder.
    joins("INNER JOIN routes rs ON rs.source_id = projects.id AND rs.source_type = 'Project'")
      .where('rs.path LIKE ?', "#{sanitize_sql_like(path)}/%")
  end

  # "enabled" here means "not disabled". It includes private features!
  scope :with_feature_enabled, ->(feature) {
    access_level_attribute = ProjectFeature.arel_table[ProjectFeature.access_level_attribute(feature)]
    enabled_feature = access_level_attribute.gt(ProjectFeature::DISABLED).or(access_level_attribute.eq(nil))

    with_project_feature.where(enabled_feature)
  }

  # Picks a feature where the level is exactly that given.
  scope :with_feature_access_level, ->(feature, level) {
    access_level_attribute = ProjectFeature.access_level_attribute(feature)
    with_project_feature.where(project_features: { access_level_attribute => level })
  }

  # Picks projects which use the given programming language
  scope :with_programming_language, ->(language_name) do
    lang_id_query = ProgrammingLanguage
        .with_name_case_insensitive(language_name)
        .select(:id)

    joins(:repository_languages)
        .where(repository_languages: { programming_language_id: lang_id_query })
  end

  scope :with_builds_enabled, -> { with_feature_enabled(:builds) }
  scope :with_issues_enabled, -> { with_feature_enabled(:issues) }
  scope :with_issues_available_for_user, ->(current_user) { with_feature_available_for_user(:issues, current_user) }
  scope :with_merge_requests_available_for_user, ->(current_user) { with_feature_available_for_user(:merge_requests, current_user) }
  scope :with_merge_requests_enabled, -> { with_feature_enabled(:merge_requests) }
  scope :with_remote_mirrors, -> { joins(:remote_mirrors).where(remote_mirrors: { enabled: true }).distinct }
  scope :with_limit, -> (maximum) { limit(maximum) }

  scope :with_group_runners_enabled, -> do
    joins(:ci_cd_settings)
    .where(project_ci_cd_settings: { group_runners_enabled: true })
  end

  scope :with_pages_deployed, -> do
    joins(:pages_metadatum).merge(ProjectPagesMetadatum.deployed)
  end

  scope :pages_metadata_not_migrated, -> do
    left_outer_joins(:pages_metadatum)
      .where(project_pages_metadata: { project_id: nil })
  end

  enum auto_cancel_pending_pipelines: { disabled: 0, enabled: 1 }

  chronic_duration_attr :build_timeout_human_readable, :build_timeout,
    default: 3600, error_message: _('Maximum job timeout has a value which could not be accepted')

  validates :build_timeout, allow_nil: true,
                            numericality: { greater_than_or_equal_to: 10.minutes,
                                            less_than: MAX_BUILD_TIMEOUT,
                                            only_integer: true,
                                            message: _('needs to be between 10 minutes and 1 month') }

  # Used by Projects::CleanupService to hold a map of rewritten object IDs
  mount_uploader :bfg_object_map, AttachmentUploader

  def self.eager_load_namespace_and_owner
    includes(namespace: :owner)
  end

  # Returns a collection of projects that is either public or visible to the
  # logged in user.
  def self.public_or_visible_to_user(user = nil, min_access_level = nil)
    min_access_level = nil if user&.admin?

    if user
      where('EXISTS (?) OR projects.visibility_level IN (?)',
            user.authorizations_for_projects(min_access_level: min_access_level),
            Gitlab::VisibilityLevel.levels_for_user(user))
    else
      public_to_user
    end
  end

  # project features may be "disabled", "internal", "enabled" or "public". If "internal",
  # they are only available to team members. This scope returns projects where
  # the feature is either public, enabled, or internal with permission for the user.
  # Note: this scope doesn't enforce that the user has access to the projects, it just checks
  # that the user has access to the feature. It's important to use this scope with others
  # that checks project authorizations first (e.g. `filter_by_feature_visibility`).
  #
  # This method uses an optimised version of `with_feature_access_level` for
  # logged in users to more efficiently get private projects with the given
  # feature.
  def self.with_feature_available_for_user(feature, user)
    visible = [ProjectFeature::ENABLED, ProjectFeature::PUBLIC]

    if user&.admin?
      with_feature_enabled(feature)
    elsif user
      min_access_level = ProjectFeature.required_minimum_access_level(feature)
      column = ProjectFeature.quoted_access_level_column(feature)

      with_project_feature
      .where("#{column} IS NULL OR #{column} IN (:public_visible) OR (#{column} = :private_visible AND EXISTS (:authorizations))",
            {
              public_visible: visible,
              private_visible: ProjectFeature::PRIVATE,
              authorizations: user.authorizations_for_projects(min_access_level: min_access_level)
            })
    else
      # This has to be added to include features whose value is nil in the db
      visible << nil
      with_feature_access_level(feature, visible)
    end
  end

  # This scope returns projects where user has access to both the project and the feature.
  def self.filter_by_feature_visibility(feature, user)
    with_feature_available_for_user(feature, user)
      .public_or_visible_to_user(
        user,
        ProjectFeature.required_minimum_access_level_for_private_project(feature)
      )
  end

  scope :active, -> { joins(:issues, :notes, :merge_requests).order('issues.created_at, notes.created_at, merge_requests.created_at DESC') }
  scope :abandoned, -> { where('projects.last_activity_at < ?', 6.months.ago) }

  scope :excluding_project, ->(project) { where.not(id: project) }

  # We require an alias to the project_mirror_data_table in order to use import_state in our queries
  scope :joins_import_state, -> { joins("INNER JOIN project_mirror_data import_state ON import_state.project_id = projects.id") }
  scope :for_group, -> (group) { where(group: group) }
  scope :for_group_and_its_subgroups, ->(group) { where(namespace_id: group.self_and_descendants.select(:id)) }

  class << self
    # Searches for a list of projects based on the query given in `query`.
    #
    # On PostgreSQL this method uses "ILIKE" to perform a case-insensitive
    # search. On MySQL a regular "LIKE" is used as it's already
    # case-insensitive.
    #
    # query - The search query as a String.
    def search(query)
      if Feature.enabled?(:project_search_by_full_path, default_enabled: true)
        joins(:route).fuzzy_search(query, [Route.arel_table[:path], :name, :description])
      else
        fuzzy_search(query, [:path, :name, :description])
      end
    end

    def search_by_title(query)
      non_archived.fuzzy_search(query, [:name])
    end

    def visibility_levels
      Gitlab::VisibilityLevel.options
    end

    def sort_by_attribute(method)
      case method.to_s
      when 'storage_size_desc'
        # storage_size is a joined column so we need to
        # pass a string to avoid AR adding the table name
        reorder('project_statistics.storage_size DESC, projects.id DESC')
      when 'latest_activity_desc'
        reorder(last_activity_at: :desc)
      when 'latest_activity_asc'
        reorder(last_activity_at: :asc)
      when 'stars_desc'
        sorted_by_stars_desc
      when 'stars_asc'
        sorted_by_stars_asc
      else
        order_by(method)
      end
    end

    def reference_pattern
      %r{
        (?<!#{Gitlab::PathRegex::PATH_START_CHAR})
        ((?<namespace>#{Gitlab::PathRegex::FULL_NAMESPACE_FORMAT_REGEX})\/)?
        (?<project>#{Gitlab::PathRegex::PROJECT_PATH_FORMAT_REGEX})
      }x
    end

    def reference_postfix
      '>'
    end

    def reference_postfix_escaped
      '&gt;'
    end

    # Pattern used to extract `namespace/project>` project references from text.
    # '>' or its escaped form ('&gt;') are checked for because '>' is sometimes escaped
    # when the reference comes from an external source.
    def markdown_reference_pattern
      %r{
        #{reference_pattern}
        (#{reference_postfix}|#{reference_postfix_escaped})
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

    # Returns ids of projects with issuables available for given user
    #
    # Used on queries to find milestones or labels which user can see
    # For example: Milestone.where(project_id: ids_with_issuables_available_for(user))
    def ids_with_issuables_available_for(user)
      with_issues_enabled = with_issues_available_for_user(user).select(:id)
      with_merge_requests_enabled = with_merge_requests_available_for_user(user).select(:id)

      from_union([with_issues_enabled, with_merge_requests_enabled]).select(:id)
    end
  end

  def initialize(attributes = nil)
    # We can't use default_value_for because the database has a default
    # value of 0 for visibility_level. If someone attempts to create a
    # private project, default_value_for will assume that the
    # visibility_level hasn't changed and will use the application
    # setting default, which could be internal or public. For projects
    # inside a private group, those levels are invalid.
    #
    # To fix the problem, we assign the actual default in the application if
    # no explicit visibility has been initialized.
    attributes ||= {}

    unless visibility_attribute_present?(attributes)
      attributes[:visibility_level] = Gitlab::CurrentSettings.default_project_visibility
    end

    super
  end

  def all_pipelines
    if builds_enabled?
      super
    else
      super.external
    end
  end

  def ci_pipelines
    if builds_enabled?
      super
    else
      super.external
    end
  end

  def preload_protected_branches
    preloader = ActiveRecord::Associations::Preloader.new
    preloader.preload(self, protected_branches: [:push_access_levels, :merge_access_levels])
  end

  # returns all ancestor-groups upto but excluding the given namespace
  # when no namespace is given, all ancestors upto the top are returned
  def ancestors_upto(top = nil, hierarchy_order: nil)
    Gitlab::ObjectHierarchy.new(Group.where(id: namespace_id))
      .base_and_ancestors(upto: top, hierarchy_order: hierarchy_order)
  end

  alias_method :ancestors, :ancestors_upto

  def emails_disabled?
    strong_memoize(:emails_disabled) do
      # disabling in the namespace overrides the project setting
      super || namespace.emails_disabled?
    end
  end

  def lfs_enabled?
    return namespace.lfs_enabled? if self[:lfs_enabled].nil?

    self[:lfs_enabled] && Gitlab.config.lfs.enabled
  end

  alias_method :lfs_enabled, :lfs_enabled?

  def auto_devops_enabled?
    if auto_devops&.enabled.nil?
      has_auto_devops_implicitly_enabled?
    else
      auto_devops.enabled?
    end
  end

  def has_auto_devops_implicitly_enabled?
    auto_devops_config = first_auto_devops_config

    auto_devops_config[:scope] != :project && auto_devops_config[:status]
  end

  def has_auto_devops_implicitly_disabled?
    auto_devops_config = first_auto_devops_config

    auto_devops_config[:scope] != :project && !auto_devops_config[:status]
  end

  def first_auto_devops_config
    return namespace.first_auto_devops_config if auto_devops&.enabled.nil?

    { scope: :project, status: auto_devops&.enabled || Feature.enabled?(:force_autodevops_on_by_default, self) }
  end

  def daily_statistics_enabled?
    Feature.enabled?(:project_daily_statistics, self, default_enabled: true)
  end

  def unlink_forks_upon_visibility_decrease_enabled?
    Feature.enabled?(:unlink_fork_network_upon_visibility_decrease, self, default_enabled: true)
  end

  def empty_repo?
    repository.empty?
  end

  def team
    @team ||= ProjectTeam.new(self)
  end

  def repository
    @repository ||= Repository.new(full_path, self, disk_path: disk_path)
  end

  def cleanup
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

  def commits_by(oids:)
    repository.commits_by(oids: oids)
  end

  # ref can't be HEAD, can only be branch/tag name
  def latest_successful_build_for_ref(job_name, ref = default_branch)
    return unless ref

    latest_pipeline = ci_pipelines.latest_successful_for_ref(ref)
    return unless latest_pipeline

    latest_pipeline.builds.latest.with_artifacts_archive.find_by(name: job_name)
  end

  def latest_successful_build_for_sha(job_name, sha)
    return unless sha

    latest_pipeline = ci_pipelines.latest_successful_for_sha(sha)
    return unless latest_pipeline

    latest_pipeline.builds.latest.with_artifacts_archive.find_by(name: job_name)
  end

  def latest_successful_build_for_ref!(job_name, ref = default_branch)
    latest_successful_build_for_ref(job_name, ref) || raise(ActiveRecord::RecordNotFound.new("Couldn't find job #{job_name}"))
  end

  def latest_pipeline_for_ref(ref = default_branch)
    ref = ref.presence || default_branch
    sha = commit(ref)&.sha

    return unless sha

    ci_pipelines.newest_first(ref: ref, sha: sha).first
  end

  def merge_base_commit(first_commit_id, second_commit_id)
    sha = repository.merge_base(first_commit_id, second_commit_id)
    commit_by(oid: sha) if sha
  end

  def saved?
    id && persisted?
  end

  def import_status
    import_state&.status || 'none'
  end

  def human_import_status_name
    import_state&.human_status_name || 'none'
  end

  def add_import_job
    job_id =
      if forked?
        RepositoryForkWorker.perform_async(id)
      elsif gitlab_project_import?
        # Do not retry on Import/Export until https://gitlab.com/gitlab-org/gitlab-foss/issues/26189 is solved.
        RepositoryImportWorker.set(retry: false).perform_async(self.id)
      else
        RepositoryImportWorker.perform_async(self.id)
      end

    log_import_activity(job_id)

    job_id
  end

  # rubocop:disable Gitlab/RailsLogger
  def log_import_activity(job_id, type: :import)
    job_type = type.to_s.capitalize

    if job_id
      Rails.logger.info("#{job_type} job scheduled for #{full_path} with job ID #{job_id}.")
    else
      Rails.logger.error("#{job_type} job failed to create for #{full_path}.")
    end
  end
  # rubocop:enable Gitlab/RailsLogger

  def reset_cache_and_import_attrs
    run_after_commit do
      ProjectCacheWorker.perform_async(self.id)
    end

    import_state.update(last_error: nil)
    remove_import_data
  end

  # This method is overridden in EE::Project model
  def remove_import_data
    import_data&.destroy
  end

  def ci_config_path=(value)
    # Strip all leading slashes so that //foo -> foo
    super(value&.delete("\0"))
  end

  def import_url=(value)
    if Gitlab::UrlSanitizer.valid?(value)
      import_url = Gitlab::UrlSanitizer.new(value)
      super(import_url.sanitized_url)
      create_or_update_import_data(credentials: import_url.credentials)
    else
      super(value)
    end
  end

  def import_url
    if import_data && super.present?
      import_url = Gitlab::UrlSanitizer.new(super, credentials: import_data.credentials)
      import_url.full_url
    else
      super
    end
  rescue
    super
  end

  def valid_import_url?
    valid?(:import_url) || errors.messages[:import_url].nil?
  end

  def create_or_update_import_data(data: nil, credentials: nil)
    return if data.nil? && credentials.nil?

    project_import_data = import_data || build_import_data

    project_import_data.merge_data(data.to_h)
    project_import_data.merge_credentials(credentials.to_h)

    project_import_data
  end

  def import?
    external_import? || forked? || gitlab_project_import? || bare_repository_import?
  end

  def external_import?
    import_url.present?
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

  def has_remote_mirror?
    remote_mirror_available? && remote_mirrors.enabled.exists?
  end

  def updating_remote_mirror?
    remote_mirrors.enabled.started.exists?
  end

  def update_remote_mirrors
    return unless remote_mirror_available?

    remote_mirrors.enabled.each(&:sync)
  end

  def mark_stuck_remote_mirrors_as_failed!
    remote_mirrors.stuck.update_all(
      update_status: :failed,
      last_error: _('The remote mirror took to long to complete.'),
      last_update_at: Time.now
    )
  end

  def mark_remote_mirrors_for_removal
    remote_mirrors.each(&:mark_for_delete_if_blank_url)
  end

  def remote_mirror_available?
    remote_mirror_available_overridden ||
      ::Gitlab::CurrentSettings.mirror_available
  end

  def check_personal_projects_limit
    # Since this method is called as validation hook, `creator` might not be
    # present. Since the validation for that will fail, we can just return
    # early.
    return if !creator || creator.can_create_project? ||
        namespace.kind == 'group'

    limit = creator.projects_limit
    error =
      if limit.zero?
        _('Personal project creation is not allowed. Please contact your administrator with questions')
      else
        _('Your project limit is %{limit} projects! Please contact your administrator to increase it')
      end

    self.errors.add(:limit_reached, error % { limit: limit })
  end

  def should_validate_visibility_level?
    new_record? || changes.has_key?(:visibility_level)
  end

  def visibility_level_allowed_by_group
    return if visibility_level_allowed_by_group?

    level_name = Gitlab::VisibilityLevel.level_name(self.visibility_level).downcase
    group_level_name = Gitlab::VisibilityLevel.level_name(self.group.visibility_level).downcase
    self.errors.add(:visibility_level, _("%{level_name} is not allowed in a %{group_level_name} group.") % { level_name: level_name, group_level_name: group_level_name })
  end

  def visibility_level_allowed_as_fork
    return if visibility_level_allowed_as_fork?

    level_name = Gitlab::VisibilityLevel.level_name(self.visibility_level).downcase
    self.errors.add(:visibility_level, _("%{level_name} is not allowed since the fork source project has lower visibility.") % { level_name: level_name })
  end

  def check_wiki_path_conflict
    return if path.blank?

    path_to_check = path.ends_with?('.wiki') ? path.chomp('.wiki') : "#{path}.wiki"

    if Project.where(namespace_id: namespace_id, path: path_to_check).exists?
      errors.add(:name, _('has already been taken'))
    end
  end

  def pages_https_only
    return false unless Gitlab.config.pages.external_https

    super
  end

  def pages_https_only?
    return false unless Gitlab.config.pages.external_https

    super
  end

  def validate_pages_https_only
    return unless pages_https_only?

    unless pages_domains.all?(&:https?)
      errors.add(:pages_https_only, _("cannot be enabled unless all domains have TLS certificates"))
    end
  end

  def to_param
    if persisted? && errors.include?(:path)
      path_was
    else
      path
    end
  end

  def to_reference_with_postfix
    "#{to_reference(full: true)}#{self.class.reference_postfix}"
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

  def web_url(only_path: nil)
    Gitlab::Routing.url_helpers.project_url(self, only_path: only_path)
  end

  def readme_url
    readme_path = repository.readme_path
    if readme_path
      Gitlab::Routing.url_helpers.project_blob_url(self, File.join(default_branch, readme_path))
    end
  end

  def new_issuable_address(author, address_type)
    return unless Gitlab::IncomingEmail.supports_issue_creation? && author

    # check since this can come from a request parameter
    return unless %w(issue merge_request).include?(address_type)

    author.ensure_incoming_email_token!

    suffix = address_type.dasherize

    # example: incoming+h5bp-html5-boilerplate-8-1234567890abcdef123456789-issue@localhost.com
    # example: incoming+h5bp-html5-boilerplate-8-1234567890abcdef123456789-merge-request@localhost.com
    Gitlab::IncomingEmail.reply_address("#{full_path_slug}-#{project_id}-#{author.incoming_email_token}-#{suffix}")
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
    available_services_names = Service.available_services_names - exceptions

    available_services = available_services_names.map do |service_name|
      find_or_initialize_service(service_name)
    end

    available_services.compact
  end

  def disabled_services
    []
  end

  def find_or_initialize_service(name)
    return if disabled_services.include?(name)

    service = find_service(services, name)
    return service if service

    # We should check if template for the service exists
    template = find_service(services_templates, name)

    if template
      Service.build_from_template(id, template)
    else
      # If no template, we should create an instance. Ex `build_gitlab_ci_service`
      public_send("build_#{name}_service") # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  # rubocop: disable CodeReuse/ServiceClass
  def create_labels
    Label.templates.each do |label|
      params = label.attributes.except('id', 'template', 'created_at', 'updated_at', 'type')
      Labels::FindOrCreateService.new(nil, self, params).execute(skip_authorization: true)
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

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

  def all_clusters
    group_clusters = Clusters::Cluster.joins(:groups).where(cluster_groups: { group_id: ancestors_upto } )
    instance_clusters = Clusters::Cluster.instance_type

    Clusters::Cluster.from_union([clusters, group_clusters, instance_clusters])
  end

  def items_for(entity)
    case entity
    when 'issue' then
      issues
    when 'merge_request' then
      merge_requests
    end
  end

  # rubocop: disable CodeReuse/ServiceClass
  def send_move_instructions(old_path_with_namespace)
    # New project path needs to be committed to the DB or notification will
    # retrieve stale information
    run_after_commit do
      NotificationService.new.project_was_moved(self, old_path_with_namespace)
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

  def owner
    if group
      group
    else
      namespace.try(:owner)
    end
  end

  def to_ability_name
    model_name.singular
  end

  # rubocop: disable CodeReuse/ServiceClass
  def execute_hooks(data, hooks_scope = :push_hooks)
    run_after_commit_or_now do
      hooks.hooks_for(hooks_scope).select_active(hooks_scope, data).each do |hook|
        hook.async_execute(data, hooks_scope.to_s)
      end
      SystemHooksService.new.execute_hooks(data, hooks_scope)
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

  def execute_services(data, hooks_scope = :push_hooks)
    # Call only service hooks that are active for this scope
    run_after_commit_or_now do
      services.public_send(hooks_scope).each do |service| # rubocop:disable GitlabSecurity/PublicSend
        service.async_execute(data)
      end
    end
  end

  def has_active_hooks?(hooks_scope = :push_hooks)
    hooks.hooks_for(hooks_scope).any? || SystemHook.hooks_for(hooks_scope).any?
  end

  def has_active_services?(hooks_scope = :push_hooks)
    services.public_send(hooks_scope).any? # rubocop:disable GitlabSecurity/PublicSend
  end

  def valid_repo?
    repository.exists?
  rescue
    errors.add(:path, _('Invalid repository path'))
    false
  end

  def url_to_repo
    gitlab_shell.url_to_repo(full_path)
  end

  def repo_exists?
    strong_memoize(:repo_exists) do
      repository.exists?
    rescue
      false
    end
  end

  def root_ref?(branch)
    repository.root_ref == branch
  end

  def ssh_url_to_repo
    url_to_repo
  end

  def http_url_to_repo
    custom_root = Gitlab::CurrentSettings.custom_http_clone_url_root

    project_url = if custom_root.present?
                    Gitlab::Utils.append_path(
                      custom_root,
                      web_url(only_path: true)
                    )
                  else
                    web_url
                  end

    "#{project_url}.git"
  end

  # Is overridden in EE
  def lfs_http_url_to_repo(_)
    http_url_to_repo
  end

  def forked?
    fork_network && fork_network.root_project != self
  end

  def fork_source
    return unless forked?

    forked_from_project || fork_network&.root_project
  end

  def lfs_storage_project
    @lfs_storage_project ||= begin
      result = self

      # TODO: Make this go to the fork_network root immeadiatly
      # dependant on the discussion in: https://gitlab.com/gitlab-org/gitlab-foss/issues/39769
      result = result.fork_source while result&.forked?

      result || self
    end
  end

  # This will return all `lfs_objects` that are accessible to the project.
  # So this might be `self.lfs_objects` if the project is not part of a fork
  # network, or it is the base of the fork network.
  #
  # TODO: refactor this to get the correct lfs objects when implementing
  #       https://gitlab.com/gitlab-org/gitlab-foss/issues/39769
  def all_lfs_objects
    lfs_storage_project.lfs_objects
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
    return false unless repository_storage

    # Check if repository with same path already exists on disk we can
    # skip this for the hashed storage because the path does not change
    if legacy_storage? && repository_with_same_path_already_exists?
      errors.add(:base, _('There is already a repository with that name on disk'))
      return false
    end

    true
  rescue GRPC::Internal # if the path is too long
    false
  end

  def track_project_repository
    repository = project_repository || build_project_repository
    repository.update!(shard_name: repository_storage, disk_path: disk_path)
  end

  def create_repository(force: false)
    # Forked import is handled asynchronously
    return if forked? && !force

    if gitlab_shell.create_project_repository(self)
      repository.after_create
      true
    else
      errors.add(:base, _('Failed to create repository via gitlab-shell'))
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

  # Filters `users` to return only authorized users of the project
  def members_among(users)
    if users.is_a?(ActiveRecord::Relation) && !users.loaded?
      authorized_users.merge(users)
    else
      return [] if users.empty?

      user_ids = authorized_users.where(users: { id: users.map(&:id) }).pluck(:id)
      users.select { |user| user_ids.include?(user.id) }
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

  def change_head(branch)
    if repository.branch_exists?(branch)
      repository.before_change_head
      repository.raw_repository.write_ref('HEAD', "refs/heads/#{branch}")
      repository.copy_gitattributes(branch)
      repository.after_change_head
      ProjectCacheWorker.perform_async(self.id, [], [:commit_count])
      reload_default_branch
    else
      errors.add(:base, _("Could not change HEAD: branch '%{branch}' does not exist") % { branch: branch })
      false
    end
  end

  def forked_from?(other_project)
    forked? && forked_from_project == other_project
  end

  def in_fork_network_of?(other_project)
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
    return if unlink_forks_upon_visibility_decrease_enabled?
    return unless visibility_level < visibility_level_before_last_save

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
    errors.add(:base, _('Failed create wiki'))
    false
  end

  def wiki
    strong_memoize(:wiki) do
      ProjectWiki.new(self, self.owner)
    end
  end

  def jira_tracker_active?
    jira_tracker? && jira_service.active
  end

  def allowed_to_share_with_group?
    !namespace.share_with_group_lock
  end

  def pipeline_for(ref, sha = nil, id = nil)
    sha ||= commit(ref).try(:sha)
    return unless sha

    if id.present?
      pipelines_for(ref, sha).find_by(id: id)
    else
      pipelines_for(ref, sha).take
    end
  end

  def pipelines_for(ref, sha)
    ci_pipelines.order(id: :desc).where(sha: sha, ref: ref)
  end

  def latest_successful_pipeline_for_default_branch
    if defined?(@latest_successful_pipeline_for_default_branch)
      return @latest_successful_pipeline_for_default_branch
    end

    @latest_successful_pipeline_for_default_branch =
      ci_pipelines.latest_successful_for_ref(default_branch)
  end

  def latest_successful_pipeline_for(ref = nil)
    if ref && ref != default_branch
      ci_pipelines.latest_successful_for_ref(ref)
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
    @shared_runners ||= shared_runners_available? ? Ci::Runner.instance_type : Ci::Runner.none
  end

  def group_runners
    @group_runners ||= group_runners_enabled? ? Ci::Runner.belonging_to_parent_group_of_project(self.id) : Ci::Runner.none
  end

  def all_runners
    Ci::Runner.from_union([runners, group_runners, shared_runners])
  end

  def active_runners
    strong_memoize(:active_runners) do
      all_runners.active
    end
  end

  def any_runners?(&block)
    active_runners.any?(&block)
  end

  def valid_runners_token?(token)
    self.runners_token && ActiveSupport::SecurityUtils.secure_compare(token, self.runners_token)
  end

  # rubocop: disable CodeReuse/ServiceClass
  def open_issues_count(current_user = nil)
    Projects::OpenIssuesCountService.new(self, current_user).count
  end
  # rubocop: enable CodeReuse/ServiceClass

  # rubocop: disable CodeReuse/ServiceClass
  def open_merge_requests_count
    Projects::OpenMergeRequestsCountService.new(self).count
  end
  # rubocop: enable CodeReuse/ServiceClass

  def visibility_level_allowed_as_fork?(level = self.visibility_level)
    return true unless forked?

    original_project = fork_source
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

  def pages_group_url
    # The host in URL always needs to be downcased
    Gitlab.config.pages.url.sub(%r{^https?://}) do |prefix|
      "#{prefix}#{pages_subdomain}."
    end.downcase
  end

  def pages_url
    url = pages_group_url
    url_path = full_path.partition('/').last

    # If the project path is the same as host, we serve it as group page
    return url if url == "#{Settings.pages.protocol}://#{url_path}"

    "#{url}/#{url_path}"
  end

  def pages_group_root?
    pages_group_url == pages_url
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
    Gitlab.config.pages.enabled
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
  # rubocop: disable CodeReuse/ServiceClass
  def remove_pages
    # Projects with a missing namespace cannot have their pages removed
    return unless namespace

    mark_pages_as_not_deployed unless destroyed?
    ::Projects::UpdatePagesConfigurationService.new(self).execute

    # 1. We rename pages to temporary directory
    # 2. We wait 5 minutes, due to NFS caching
    # 3. We asynchronously remove pages with force
    temp_path = "#{path}.#{SecureRandom.hex}.deleted"

    if Gitlab::PagesTransfer.new.rename_project(path, temp_path, namespace.full_path)
      PagesWorker.perform_in(5.minutes, :remove, namespace.full_path, temp_path)
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

  def mark_pages_as_deployed
    ensure_pages_metadatum.update!(deployed: true)
  end

  def mark_pages_as_not_deployed
    ensure_pages_metadatum.update!(deployed: false)
  end

  # rubocop:disable Gitlab/RailsLogger
  def write_repository_config(gl_full_path: full_path)
    # We'd need to keep track of project full path otherwise directory tree
    # created with hashed storage enabled cannot be usefully imported using
    # the import rake task.
    repository.raw_repository.write_config(full_path: gl_full_path)
  rescue Gitlab::Git::Repository::NoRepository => e
    Rails.logger.error("Error writing to .git/config for project #{full_path} (#{id}): #{e.message}.")
    nil
  end
  # rubocop:enable Gitlab/RailsLogger

  def after_import
    repository.after_import
    wiki.repository.after_import

    # The import assigns iid values on its own, e.g. by re-using GitHub ids.
    # Flush existing InternalId records for this project for consistency reasons.
    # Those records are going to be recreated with the next normal creation
    # of a model instance (e.g. an Issue).
    InternalId.flush_records!(project: self)

    import_state.finish
    update_project_counter_caches
    after_create_default_branch
    join_pool_repository
    refresh_markdown_cache!
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

  # rubocop: disable CodeReuse/ServiceClass
  def after_create_default_branch
    Projects::ProtectDefaultBranchService.new(self).execute
  end
  # rubocop: enable CodeReuse/ServiceClass

  # Lazy loading of the `pipeline_status` attribute
  def pipeline_status
    @pipeline_status ||= Gitlab::Cache::Ci::ProjectPipelineStatus.load_for_project(self)
  end

  # rubocop:disable Gitlab/RailsLogger
  def add_export_job(current_user:, after_export_strategy: nil, params: {})
    job_id = ProjectExportWorker.perform_async(current_user.id, self.id, after_export_strategy, params)

    if job_id
      Rails.logger.info "Export job started for project ID #{self.id} with job ID #{job_id}"
    else
      Rails.logger.error "Export job failed to start for project ID #{self.id}"
    end
  end
  # rubocop:enable Gitlab/RailsLogger

  def import_export_shared
    @import_export_shared ||= Gitlab::ImportExport::Shared.new(self)
  end

  def export_path
    return unless namespace.present? || hashed_storage?(:repository)

    import_export_shared.archive_path
  end

  def export_status
    if export_in_progress?
      :started
    elsif after_export_in_progress?
      :after_export_action
    elsif export_file_exists?
      :finished
    else
      :none
    end
  end

  def export_in_progress?
    import_export_shared.active_export_count > 0
  end

  def after_export_in_progress?
    import_export_shared.after_export_in_progress?
  end

  def remove_exports
    return unless export_file_exists?

    import_export_upload.remove_export_file!
    import_export_upload.save unless import_export_upload.destroyed?
  end

  def export_file_exists?
    export_file&.file
  end

  def export_file
    import_export_upload&.export_file
  end

  def full_path_slug
    Gitlab::Utils.slugify(full_path.to_s)
  end

  def has_ci?
    repository.gitlab_ci_yml || auto_devops_enabled?
  end

  def predefined_variables
    Gitlab::Ci::Variables::Collection.new
      .concat(predefined_ci_server_variables)
      .concat(predefined_project_variables)
      .concat(pages_variables)
      .concat(container_registry_variables)
      .concat(auto_devops_variables)
      .concat(api_variables)
  end

  def predefined_project_variables
    Gitlab::Ci::Variables::Collection.new
      .append(key: 'GITLAB_FEATURES', value: licensed_features.join(','))
      .append(key: 'CI_PROJECT_ID', value: id.to_s)
      .append(key: 'CI_PROJECT_NAME', value: path)
      .append(key: 'CI_PROJECT_TITLE', value: title)
      .append(key: 'CI_PROJECT_PATH', value: full_path)
      .append(key: 'CI_PROJECT_PATH_SLUG', value: full_path_slug)
      .append(key: 'CI_PROJECT_NAMESPACE', value: namespace.full_path)
      .append(key: 'CI_PROJECT_URL', value: web_url)
      .append(key: 'CI_PROJECT_VISIBILITY', value: Gitlab::VisibilityLevel.string_level(visibility_level))
      .append(key: 'CI_PROJECT_REPOSITORY_LANGUAGES', value: repository_languages.map(&:name).join(',').downcase)
      .append(key: 'CI_DEFAULT_BRANCH', value: default_branch)
  end

  def predefined_ci_server_variables
    Gitlab::Ci::Variables::Collection.new
      .append(key: 'CI', value: 'true')
      .append(key: 'GITLAB_CI', value: 'true')
      .append(key: 'CI_SERVER_HOST', value: Gitlab.config.gitlab.host)
      .append(key: 'CI_SERVER_NAME', value: 'GitLab')
      .append(key: 'CI_SERVER_VERSION', value: Gitlab::VERSION)
      .append(key: 'CI_SERVER_VERSION_MAJOR', value: Gitlab.version_info.major.to_s)
      .append(key: 'CI_SERVER_VERSION_MINOR', value: Gitlab.version_info.minor.to_s)
      .append(key: 'CI_SERVER_VERSION_PATCH', value: Gitlab.version_info.patch.to_s)
      .append(key: 'CI_SERVER_REVISION', value: Gitlab.revision)
  end

  def pages_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      break unless pages_enabled?

      variables.append(key: 'CI_PAGES_DOMAIN', value: Gitlab.config.pages.host)
      variables.append(key: 'CI_PAGES_URL', value: pages_url)
    end
  end

  def api_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: 'CI_API_V4_URL', value: API::Helpers::Version.new('v4').root_url)
    end
  end

  def container_registry_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      break variables unless Gitlab.config.registry.enabled

      variables.append(key: 'CI_REGISTRY', value: Gitlab.config.registry.host_port)

      if container_registry_enabled?
        variables.append(key: 'CI_REGISTRY_IMAGE', value: container_registry_url)
      end
    end
  end

  def default_environment
    production_first = Arel.sql("(CASE WHEN name = 'production' THEN 0 ELSE 1 END), id ASC")

    environments
      .with_state(:available)
      .reorder(production_first)
      .first
  end

  def ci_variables_for(ref:, environment: nil)
    result = if protected_for?(ref)
               variables
             else
               variables.unprotected
             end

    if environment
      result.on_environment(environment)
    else
      result.where(environment_scope: '*')
    end
  end

  def protected_for?(ref)
    raise Repository::AmbiguousRefError if repository.ambiguous_ref?(ref)

    resolved_ref = repository.expand_ref(ref) || ref
    return false unless Gitlab::Git.tag_ref?(resolved_ref) || Gitlab::Git.branch_ref?(resolved_ref)

    ref_name = if resolved_ref == ref
                 Gitlab::Git.ref_name(resolved_ref)
               else
                 ref
               end

    if Gitlab::Git.branch_ref?(resolved_ref)
      ProtectedBranch.protected?(self, ref_name)
    elsif Gitlab::Git.tag_ref?(resolved_ref)
      ProtectedTag.protected?(self, ref_name)
    end
  end

  def deployment_variables(environment:, kubernetes_namespace: nil)
    platform = deployment_platform(environment: environment)

    return [] unless platform.present?

    platform.predefined_variables(
      project: self,
      environment_name: environment,
      kubernetes_namespace: kubernetes_namespace
    )
  end

  def auto_devops_variables
    return [] unless auto_devops_enabled?

    (auto_devops || build_auto_devops)&.predefined_variables
  end

  # Tries to set repository as read_only, checking for existing Git transfers in progress beforehand
  #
  # @return [Boolean] true when set to read_only or false when an existing git transfer is in progress
  def set_repository_read_only!
    with_lock do
      break false if git_transfer_in_progress?

      update_column(:repository_read_only, true)
    end
  end

  # Set repository as writable again
  def set_repository_writable!
    with_lock do
      update_column(:repository_read_only, false)
    end
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

        Gitlab::RouteMap.new(data) if data
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
    return self unless forked_from_project
    return self unless forked_from_project.merge_requests_enabled?

    # When our current visibility is more restrictive than the source project,
    # (e.g., the fork is `private` but the parent is `public`), target the less
    # permissive project
    if visibility_level_value < forked_from_project.visibility_level_value
      self
    else
      forked_from_project
    end
  end

  def multiple_issue_boards_available?
    true
  end

  def full_path_before_last_save
    File.join(namespace.full_path, path_before_last_save)
  end

  alias_method :name_with_namespace, :full_name
  alias_method :human_name, :full_name
  # @deprecated cannot remove yet because it has an index with its name in elasticsearch
  alias_method :path_with_namespace, :full_path

  # rubocop: disable CodeReuse/ServiceClass
  def forks_count
    Projects::ForksCountService.new(self).count
  end
  # rubocop: enable CodeReuse/ServiceClass

  def legacy_storage?
    [nil, 0].include?(self.storage_version)
  end

  # Check if Hashed Storage is enabled for the project with at least informed feature rolled out
  #
  # @param [Symbol] feature that needs to be rolled out for the project (:repository, :attachments)
  def hashed_storage?(feature)
    raise ArgumentError, _("Invalid feature") unless HASHED_STORAGE_FEATURES.include?(feature)

    self.storage_version && self.storage_version >= HASHED_STORAGE_FEATURES[feature]
  end

  def renamed?
    persisted? && path_changed?
  end

  def human_merge_method
    if merge_method == :ff
      'Fast-forward'
    else
      merge_method.to_s.humanize
    end
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
    return unless storage_upgradable?

    if git_transfer_in_progress?
      HashedStorage::ProjectMigrateWorker.perform_in(Gitlab::ReferenceCounter::REFERENCE_EXPIRE_TIME, id)
    else
      HashedStorage::ProjectMigrateWorker.perform_async(id)
    end
  end

  def rollback_to_legacy_storage!
    return if legacy_storage?

    if git_transfer_in_progress?
      HashedStorage::ProjectRollbackWorker.perform_in(Gitlab::ReferenceCounter::REFERENCE_EXPIRE_TIME, id)
    else
      HashedStorage::ProjectRollbackWorker.perform_async(id)
    end
  end

  def git_transfer_in_progress?
    repo_reference_count > 0 || wiki_reference_count > 0
  end

  def storage_version=(value)
    super

    @storage = nil if storage_version_changed?
  end

  def reference_counter(type: Gitlab::GlRepository::PROJECT)
    Gitlab::ReferenceCounter.new(type.identifier_for_subject(self))
  end

  def badges
    return project_badges unless group

    Badge.from_union([
      project_badges,
      GroupBadge.where(group: group.self_and_ancestors)
    ])
  end

  def merge_requests_allowing_push_to_user(user)
    return MergeRequest.none unless user

    developer_access_exists = user.project_authorizations
                                .where('access_level >= ? ', Gitlab::Access::DEVELOPER)
                                .where('project_authorizations.project_id = merge_requests.target_project_id')
                                .limit(1)
                                .select(1)
    merge_requests_allowing_collaboration.where('EXISTS (?)', developer_access_exists)
  end

  def any_branch_allows_collaboration?(user)
    fetch_branch_allows_collaboration(user)
  end

  def branch_allows_collaboration?(user, branch_name)
    fetch_branch_allows_collaboration(user, branch_name)
  end

  def external_authorization_classification_label
    super || ::Gitlab::CurrentSettings.current_application_settings
               .external_authorization_service_default_label
  end

  def licensed_features
    []
  end

  def toggle_ci_cd_settings!(settings_attribute)
    ci_cd_settings.toggle!(settings_attribute)
  end

  def gitlab_deploy_token
    @gitlab_deploy_token ||= deploy_tokens.gitlab_deploy_token
  end

  def any_lfs_file_locks?
    lfs_file_locks.any?
  end
  request_cache(:any_lfs_file_locks?) { self.id }

  def auto_cancel_pending_pipelines?
    auto_cancel_pending_pipelines == 'enabled'
  end

  def storage
    @storage ||=
      if hashed_storage?(:repository)
        Storage::HashedProject.new(self)
      else
        Storage::LegacyProject.new(self)
      end
  end

  def storage_upgradable?
    storage_version != LATEST_STORAGE_VERSION
  end

  def snippets_visible?(user = nil)
    Ability.allowed?(user, :read_project_snippet, self)
  end

  def max_attachment_size
    Gitlab::CurrentSettings.max_attachment_size.megabytes.to_i
  end

  def object_pool_params
    return {} unless !forked? && git_objects_poolable?

    {
      repository_storage: repository_storage,
      pool_repository:    pool_repository || create_new_pool_repository
    }
  end

  # Git objects are only poolable when the project is or has:
  # - Hashed storage -> The object pool will have a remote to its members, using relative paths.
  #                     If the repository path changes we would have to update the remote.
  # - not private    -> The visibility level or repository access level has to be greater than private
  #                     to prevent fetching objects that might not exist
  # - Repository     -> Else the disk path will be empty, and there's nothing to pool
  def git_objects_poolable?
    hashed_storage?(:repository) &&
      visibility_level > Gitlab::VisibilityLevel::PRIVATE &&
      repository_access_level > ProjectFeature::PRIVATE &&
      repository_exists? &&
      Gitlab::CurrentSettings.hashed_storage_enabled
  end

  def leave_pool_repository
    pool_repository&.mark_obsolete_if_last(repository) && update_column(:pool_repository_id, nil)
  end

  def link_pool_repository
    pool_repository&.link_repository(repository)
  end

  def has_pool_repository?
    pool_repository.present?
  end

  def access_request_approvers_to_be_notified
    members.maintainers.order_recent_sign_in.limit(ACCESS_REQUEST_APPROVERS_TO_BE_NOTIFIED_LIMIT)
  end

  def pages_lookup_path(trim_prefix: nil, domain: nil)
    Pages::LookupPath.new(self, trim_prefix: trim_prefix, domain: domain)
  end

  def closest_setting(name)
    setting = read_attribute(name)
    setting = closest_namespace_setting(name) if setting.nil?
    setting = app_settings_for(name) if setting.nil?
    setting
  end

  def drop_visibility_level!
    if group && group.visibility_level < visibility_level
      self.visibility_level = group.visibility_level
    end

    if Gitlab::CurrentSettings.restricted_visibility_levels.include?(visibility_level)
      self.visibility_level = Gitlab::VisibilityLevel::PRIVATE
    end
  end

  private

  def closest_namespace_setting(name)
    namespace.closest_setting(name)
  end

  def app_settings_for(name)
    Gitlab::CurrentSettings.send(name) # rubocop:disable GitlabSecurity/PublicSend
  end

  def merge_requests_allowing_collaboration(source_branch = nil)
    relation = source_of_merge_requests.opened.where(allow_collaboration: true)
    relation = relation.where(source_branch: source_branch) if source_branch
    relation
  end

  def create_new_pool_repository
    pool = PoolRepository.safe_find_or_create_by!(shard: Shard.by_name(repository_storage), source_project: self)
    update!(pool_repository: pool)

    pool.schedule unless pool.scheduled?

    pool
  end

  def join_pool_repository
    return unless pool_repository

    ObjectPool::JoinWorker.perform_async(pool_repository.id, self.id)
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
    reference_counter(type: Gitlab::GlRepository::WIKI).value
  end

  def check_repository_absence!
    return if skip_disk_validation

    if repository_storage.blank? || repository_with_same_path_already_exists?
      errors.add(:base, _('There is already a repository with that name on disk'))
      throw :abort
    end
  end

  def repository_with_same_path_already_exists?
    gitlab_shell.repository_exists?(repository_storage, "#{disk_path}.git")
  end

  def set_timestamps_for_create
    update_columns(last_activity_at: self.created_at, last_repository_updated_at: self.created_at)
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

    errors.add(:base, _("The project is still being deleted. Please try again later."))
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

  def fetch_branch_allows_collaboration(user, branch_name = nil)
    return false unless user

    Gitlab::SafeRequestStore.fetch("project-#{id}:branch-#{branch_name}:user-#{user.id}:branch_allows_collaboration") do
      next false if empty_repo?

      # Issue for N+1: https://gitlab.com/gitlab-org/gitlab-foss/issues/49322
      Gitlab::GitalyClient.allow_n_plus_1_calls do
        merge_requests_allowing_collaboration(branch_name).any? do |merge_request|
          merge_request.can_be_merged_by?(user)
        end
      end
    end
  end

  def services_templates
    @services_templates ||= Service.where(template: true)
  end

  def ensure_pages_metadatum
    pages_metadatum || create_pages_metadatum!
  rescue ActiveRecord::RecordNotUnique
    reset
    retry
  end
end

Project.prepend_if_ee('EE::Project')
