# frozen_string_literal: true

require 'carrierwave/orm/activerecord'

class Project < ApplicationRecord
  include Gitlab::ConfigHelper
  include Gitlab::VisibilityLevel
  include AccessRequestable
  include Avatarable
  include CacheMarkdownField
  include Sortable
  include AfterCommitQueue
  include CaseSensitivity
  include TokenAuthenticatable
  include ValidAttribute
  include ProjectAPICompatibility
  include ProjectFeaturesCompatibility
  include SelectForProjectAuthorization
  include Presentable
  include HasRepository
  include HasWiki
  include WebHooks::HasWebHooks
  include CanMoveRepositoryStorage
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
  include ::Repositories::CanHousekeepRepository
  include EachBatch
  include GitlabRoutingHelper
  include BulkMemberAccessLoad
  include BulkUsersByEmailLoad
  include RunnerTokenExpirationInterval
  include BlocksUnsafeSerialization
  include Subquery
  include IssueParent
  include WorkItems::Parent
  include UpdatedAtFilterable
  include CrossDatabaseIgnoredTables
  include UseSqlFunctionForPrimaryKeyLookups
  include Importable
  include SafelyChangeColumnDefault
  include Todoable

  columns_changing_default :organization_id

  ignore_column :emails_disabled, remove_with: '16.3', remove_after: '2023-08-22'

  cross_database_ignore_tables %w[routes redirect_routes], url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424277'

  extend Gitlab::Cache::RequestCache
  extend Gitlab::Utils::Override

  extend Gitlab::ConfigHelper

  BoardLimitExceeded = Class.new(StandardError)
  ExportLimitExceeded = Class.new(StandardError)

  EPOCH_CACHE_EXPIRATION = 30.days
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
  VALID_IMPORT_PROTOCOLS = %w[http https git].freeze

  VALID_MIRROR_PORTS = [22, 80, 443].freeze
  VALID_MIRROR_PROTOCOLS = %w[http https ssh git].freeze

  SORTING_PREFERENCE_FIELD = :projects_sort
  MAX_BUILD_TIMEOUT = 1.month

  GL_REPOSITORY_TYPES = [Gitlab::GlRepository::PROJECT, Gitlab::GlRepository::WIKI, Gitlab::GlRepository::DESIGN].freeze

  MAX_SUGGESTIONS_TEMPLATE_LENGTH = 255
  MAX_COMMIT_TEMPLATE_LENGTH = 500

  INSTANCE_RUNNER_RUNNING_JOBS_MAX_BUCKET = 5

  DEFAULT_MERGE_COMMIT_TEMPLATE = <<~MSG.rstrip.freeze
    Merge branch '%{source_branch}' into '%{target_branch}'

    %{title}

    %{issues}

    See merge request %{reference}
  MSG

  DEFAULT_SQUASH_COMMIT_TEMPLATE = '%{title}'

  PROJECT_FEATURES_DEFAULTS = {
    issues: gitlab_config_features.issues,
    merge_requests: gitlab_config_features.merge_requests,
    builds: gitlab_config_features.builds,
    wiki: gitlab_config_features.wiki,
    snippets: gitlab_config_features.snippets
  }.freeze

  # List of attributes that, when updated, should be considered as Project Activity
  PROJECT_ACTIVITY_ATTRIBUTES = %w[description name].freeze

  cache_markdown_field :description, pipeline: :description

  attribute :packages_enabled, default: true
  attribute :archived, default: false
  attribute :resolve_outdated_diff_discussions, default: false
  attribute :repository_storage, default: -> { Repository.pick_storage_shard }
  attribute :shared_runners_enabled, default: -> { Gitlab::CurrentSettings.shared_runners_enabled }
  attribute :only_allow_merge_if_all_discussions_are_resolved, default: false
  attribute :remove_source_branch_after_merge, default: true
  attribute :autoclose_referenced_issues, default: true
  attribute :ci_config_path, default: -> { Gitlab::CurrentSettings.default_ci_config_path }

  add_authentication_token_field :runners_token,
    encrypted: :required,
    format_with_prefix: :runners_token_prefix,
    require_prefix_for_validation: true

  # Storage specific hooks
  after_initialize :use_hashed_storage
  after_initialize :set_project_feature_defaults, if: :new_record?

  before_validation :mark_remote_mirrors_for_removal, if: -> { RemoteMirror.table_exists? }
  before_validation :ensure_project_namespace_in_sync
  before_validation :set_package_registry_access_level, if: :packages_enabled_changed?
  before_validation :remove_leading_spaces_on_name
  before_validation :set_last_activity_at

  after_validation :check_pending_delete

  before_save :ensure_runners_token

  after_create -> { create_or_load_association(:project_feature) }
  after_create -> { create_or_load_association(:ci_cd_settings) }
  after_create -> { create_or_load_association(:container_expiration_policy) }
  after_create -> { create_or_load_association(:pages_metadatum) }
  after_create :set_timestamps_for_create
  after_create :check_repository_absence!

  after_update :enqueue_catalog_resource_sync_event_worker,
    if: -> { catalog_resource && (saved_change_to_name? || saved_change_to_description? || saved_change_to_visibility_level?) }

  before_destroy :remove_private_deploy_keys
  after_destroy :remove_exports

  after_save :update_project_statistics, if: :saved_change_to_namespace_id?

  after_save :schedule_sync_event_worker, if: -> { saved_change_to_id? || saved_change_to_namespace_id? }

  after_save :create_import_state, if: ->(project) { project.import? && project.import_state.nil? }

  after_save :save_topics

  after_save :reload_project_namespace_details

  use_fast_destroy :build_trace_chunks

  has_many :project_topics, -> { order(:id) }, class_name: 'Projects::ProjectTopic'
  has_many :topics, through: :project_topics, class_name: 'Projects::Topic'

  attr_accessor :old_path_with_namespace
  attr_accessor :template_name
  attr_writer :pipeline_status
  attr_accessor :skip_disk_validation
  attr_writer :topic_list

  alias_attribute :title, :name

  # Relations
  belongs_to :pool_repository
  belongs_to :creator, class_name: 'User'
  belongs_to :organization, class_name: 'Organizations::Organization'
  belongs_to :group, -> { where(type: Group.sti_name) }, foreign_key: 'namespace_id'
  alias_method :notification_group, :group
  belongs_to :namespace
  # Sync deletion via DB Trigger to ensure we do not have
  # a project without a project_namespace (or vice-versa)
  belongs_to :project_namespace, autosave: true, class_name: 'Namespaces::ProjectNamespace', foreign_key: 'project_namespace_id', inverse_of: :project
  alias_method :parent, :namespace
  alias_attribute :parent_id, :namespace_id

  has_one :catalog_resource, class_name: 'Ci::Catalog::Resource', inverse_of: :project
  has_many :ci_components, class_name: 'Ci::Catalog::Resources::Component', inverse_of: :project
  # These are usages of the ci_components owned (not used) by the project
  has_many :ci_component_last_usages, class_name: 'Ci::Catalog::Resources::Components::LastUsage', inverse_of: :component_project
  has_many :ci_component_usages, class_name: 'Ci::Catalog::Resources::Components::Usage', inverse_of: :project
  has_many :catalog_resource_versions, class_name: 'Ci::Catalog::Resources::Version', inverse_of: :project
  has_many :catalog_resource_sync_events, class_name: 'Ci::Catalog::Resources::SyncEvent', inverse_of: :project

  has_one :last_event, -> { order 'events.created_at DESC' }, class_name: 'Event'
  has_many :boards

  def self.integration_association_name(name)
    "#{name}_integration"
  end

  # Project integrations
  has_one :apple_app_store_integration, class_name: 'Integrations::AppleAppStore'
  has_one :asana_integration, class_name: 'Integrations::Asana'
  has_one :assembla_integration, class_name: 'Integrations::Assembla'
  has_one :bamboo_integration, class_name: 'Integrations::Bamboo'
  has_one :beyond_identity_integration, class_name: 'Integrations::BeyondIdentity'
  has_one :bugzilla_integration, class_name: 'Integrations::Bugzilla'
  has_one :buildkite_integration, class_name: 'Integrations::Buildkite'
  has_one :campfire_integration, class_name: 'Integrations::Campfire'
  has_one :clickup_integration, class_name: 'Integrations::Clickup'
  has_one :confluence_integration, class_name: 'Integrations::Confluence'
  has_one :custom_issue_tracker_integration, class_name: 'Integrations::CustomIssueTracker'
  has_one :datadog_integration, class_name: 'Integrations::Datadog'
  has_one :container_registry_data_repair_detail, class_name: 'ContainerRegistry::DataRepairDetail'
  has_one :diffblue_cover_integration, class_name: 'Integrations::DiffblueCover'
  has_one :discord_integration, class_name: 'Integrations::Discord'
  has_one :drone_ci_integration, class_name: 'Integrations::DroneCi'
  has_one :emails_on_push_integration, class_name: 'Integrations::EmailsOnPush'
  has_one :ewm_integration, class_name: 'Integrations::Ewm'
  has_one :external_wiki_integration, class_name: 'Integrations::ExternalWiki'
  has_one :gitlab_slack_application_integration, class_name: 'Integrations::GitlabSlackApplication'
  has_one :google_play_integration, class_name: 'Integrations::GooglePlay'
  has_one :hangouts_chat_integration, class_name: 'Integrations::HangoutsChat'
  has_one :harbor_integration, class_name: 'Integrations::Harbor'
  has_one :irker_integration, class_name: 'Integrations::Irker'
  has_one :jenkins_integration, class_name: 'Integrations::Jenkins'
  has_one :jira_integration, class_name: 'Integrations::Jira'
  has_one :jira_cloud_app_integration, class_name: 'Integrations::JiraCloudApp'
  has_one :mattermost_integration, class_name: 'Integrations::Mattermost'
  has_one :mattermost_slash_commands_integration, class_name: 'Integrations::MattermostSlashCommands'
  has_one :matrix_integration, class_name: 'Integrations::Matrix'
  has_one :microsoft_teams_integration, class_name: 'Integrations::MicrosoftTeams'
  has_one :mock_ci_integration, class_name: 'Integrations::MockCi'
  has_one :mock_monitoring_integration, class_name: 'Integrations::MockMonitoring'
  has_one :packagist_integration, class_name: 'Integrations::Packagist'
  has_one :phorge_integration, class_name: 'Integrations::Phorge'
  has_one :pipelines_email_integration, class_name: 'Integrations::PipelinesEmail'
  has_one :pivotaltracker_integration, class_name: 'Integrations::Pivotaltracker'
  has_one :prometheus_integration, class_name: 'Integrations::Prometheus', inverse_of: :project
  has_one :pumble_integration, class_name: 'Integrations::Pumble'
  has_one :pushover_integration, class_name: 'Integrations::Pushover'
  has_one :redmine_integration, class_name: 'Integrations::Redmine'
  has_one :slack_integration, class_name: 'Integrations::Slack'
  has_one :slack_slash_commands_integration, class_name: 'Integrations::SlackSlashCommands'
  has_one :squash_tm_integration, class_name: 'Integrations::SquashTm'
  has_one :teamcity_integration, class_name: 'Integrations::Teamcity'
  has_one :telegram_integration, class_name: 'Integrations::Telegram'
  has_one :unify_circuit_integration, class_name: 'Integrations::UnifyCircuit'
  has_one :webex_teams_integration, class_name: 'Integrations::WebexTeams'
  has_one :youtrack_integration, class_name: 'Integrations::Youtrack'
  has_one :zentao_integration, class_name: 'Integrations::Zentao'

  has_one :wiki_repository, class_name: 'Projects::WikiRepository', inverse_of: :project
  has_one :design_management_repository, class_name: 'DesignManagement::Repository', inverse_of: :project
  has_one :root_of_fork_network, foreign_key: 'root_project_id', inverse_of: :root_project, class_name: 'ForkNetwork'
  has_one :fork_network_member
  has_one :fork_network, through: :fork_network_member
  has_one :forked_from_project, through: :fork_network_member

  # Projects with a very large number of notes may time out destroying them
  # through the foreign key. Additionally, the deprecated attachment uploader
  # for notes requires us to use dependent: :destroy to avoid orphaning uploaded
  # files.
  #
  # https://gitlab.com/gitlab-org/gitlab/-/issues/207222
  # Order of this association is important for project deletion.
  # has_many :notes` should be the first association among all `has_many` associations.
  has_many :notes, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  has_many :forked_to_members, class_name: 'ForkNetworkMember', foreign_key: 'forked_from_project_id'
  has_many :forks, through: :forked_to_members, source: :project, inverse_of: :forked_from_project
  has_many :fork_network_projects, through: :fork_network, source: :projects

  # Packages
  has_many :packages, class_name: 'Packages::Package'
  has_many :package_files, through: :packages, class_name: 'Packages::PackageFile'
  # repository_files must be destroyed by ruby code in order to properly remove carrierwave uploads
  has_many :rpm_repository_files,
    inverse_of: :project,
    class_name: 'Packages::Rpm::RepositoryFile',
    dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  # debian_distributions and associated component_files must be destroyed by ruby code in order to properly remove carrierwave uploads
  has_many :debian_distributions,
    class_name: 'Packages::Debian::ProjectDistribution',
    dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :npm_metadata_caches, class_name: 'Packages::Npm::MetadataCache'
  has_one :packages_cleanup_policy, class_name: 'Packages::Cleanup::Policy', inverse_of: :project
  has_many :package_protection_rules,
    class_name: 'Packages::Protection::Rule',
    inverse_of: :project

  has_one :import_state, autosave: true, class_name: 'ProjectImportState', inverse_of: :project
  has_many :import_export_uploads, dependent: :destroy, inverse_of: :project # rubocop:disable Cop/ActiveRecordDependent -- Previously was has_one association, dependent: :destroy to be removed in a separate issue and cascade FK will be added
  has_many :relation_import_trackers, class_name: 'Projects::ImportExport::RelationImportTracker', inverse_of: :project
  has_many :export_jobs, class_name: 'ProjectExportJob'
  has_many :bulk_import_exports, class_name: 'BulkImports::Export', inverse_of: :project
  has_one :project_repository, inverse_of: :project
  has_one :incident_management_setting, inverse_of: :project, class_name: 'IncidentManagement::ProjectIncidentManagementSetting'
  has_one :error_tracking_setting, inverse_of: :project, class_name: 'ErrorTracking::ProjectErrorTrackingSetting'
  has_one :grafana_integration, inverse_of: :project
  has_one :project_setting, inverse_of: :project, autosave: true
  has_one :alerting_setting, inverse_of: :project, class_name: 'Alerting::ProjectAlertingSetting'
  has_one :service_desk_setting, class_name: 'ServiceDeskSetting'
  has_one :service_desk_custom_email_verification, class_name: 'ServiceDesk::CustomEmailVerification'
  has_one :service_desk_custom_email_credential, class_name: 'ServiceDesk::CustomEmailCredential'

  # Merge requests for target project should be removed with it
  has_many :merge_requests, foreign_key: 'target_project_id', inverse_of: :target_project, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :merge_request_metrics, foreign_key: 'target_project', class_name: 'MergeRequest::Metrics', inverse_of: :target_project
  has_many :source_of_merge_requests, foreign_key: 'source_project_id', class_name: 'MergeRequest'
  has_many :issues, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :work_items # the issues relation will handle any destroys
  has_many :incident_management_issuable_escalation_statuses, through: :issues, inverse_of: :project, class_name: 'IncidentManagement::IssuableEscalationStatus'
  has_many :incident_management_timeline_event_tags, inverse_of: :project, class_name: 'IncidentManagement::TimelineEventTag'
  has_many :labels, class_name: 'ProjectLabel', dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :events
  has_many :milestones

  has_many :integrations
  has_many :alert_hooks_integrations, -> { alert_hooks }, class_name: 'Integration'
  has_many :incident_hooks_integrations, -> { incident_hooks }, class_name: 'Integration'
  has_many :archive_trace_hooks_integrations, -> { archive_trace_hooks }, class_name: 'Integration'
  has_many :confidential_issue_hooks_integrations, -> { confidential_issue_hooks }, class_name: 'Integration'
  has_many :confidential_note_hooks_integrations, -> { confidential_note_hooks }, class_name: 'Integration'
  has_many :deployment_hooks_integrations, -> { deployment_hooks }, class_name: 'Integration'
  has_many :issue_hooks_integrations, -> { issue_hooks }, class_name: 'Integration'
  has_many :job_hooks_integrations, -> { job_hooks }, class_name: 'Integration'
  has_many :merge_request_hooks_integrations, -> { merge_request_hooks }, class_name: 'Integration'
  has_many :note_hooks_integrations, -> { note_hooks }, class_name: 'Integration'
  has_many :pipeline_hooks_integrations, -> { pipeline_hooks }, class_name: 'Integration'
  has_many :push_hooks_integrations, -> { push_hooks }, class_name: 'Integration'
  has_many :tag_push_hooks_integrations, -> { tag_push_hooks }, class_name: 'Integration'
  has_many :wiki_page_hooks_integrations, -> { wiki_page_hooks }, class_name: 'Integration'
  has_many :snippets, class_name: 'ProjectSnippet'
  has_many :hooks, class_name: 'ProjectHook'
  has_many :protected_branches
  has_many :exported_protected_branches
  has_many :all_protected_branches, ->(project) { ProtectedBranch.unscope(:where).from_union(project.protected_branches, project.group_protected_branches) }, class_name: 'ProtectedBranch'

  has_many :protected_tags
  has_many :repository_languages, -> { order "share DESC" }
  has_many :designs, inverse_of: :project, class_name: 'DesignManagement::Design'

  has_many :project_authorizations
  has_many :authorized_users, -> { allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/422045') },
    through: :project_authorizations, source: :user, class_name: 'User'

  has_many :project_members, -> { non_request },
    as: :source, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
  alias_method :members, :project_members
  has_many :namespace_members, ->(project) { where(requested_at: nil).unscope(where: %i[source_id source_type]) },
    primary_key: :project_namespace_id, foreign_key: :member_namespace_id, inverse_of: :project, class_name: 'ProjectMember'

  has_many :requesters, -> { where.not(requested_at: nil) },
    as: :source, class_name: 'ProjectMember', dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
  has_many :namespace_requesters, ->(project) { where.not(requested_at: nil).unscope(where: %i[source_id source_type]) },
    primary_key: :project_namespace_id, foreign_key: :member_namespace_id, inverse_of: :project, class_name: 'ProjectMember'

  has_many :members_and_requesters, as: :source, class_name: 'ProjectMember'
  has_many :member_approvals, through: :members_and_requesters

  has_many :namespace_members_and_requesters, -> { unscope(where: %i[source_id source_type]) },
    primary_key: :project_namespace_id, foreign_key: :member_namespace_id, inverse_of: :project,
    class_name: 'ProjectMember'

  has_many :users, -> { allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/422405") },
    through: :project_members

  has_many :maintainers,
    -> do
      allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/422405")
        .where(members: { access_level: Gitlab::Access::MAINTAINER })
    end,
    through: :project_members,
    source: :user

  has_many :owners_and_maintainers,
    -> do
      where(members: { access_level: [Gitlab::Access::OWNER, Gitlab::Access::MAINTAINER] })
    end,
    through: :project_members,
    source: :user

  has_many :project_callouts, class_name: 'Users::ProjectCallout', foreign_key: :project_id

  has_many :deploy_keys_projects, inverse_of: :project
  has_many :deploy_keys, through: :deploy_keys_projects
  has_many :users_star_projects
  has_many :starrers, through: :users_star_projects, source: :user
  has_many :releases
  has_many :lfs_objects_projects
  has_many :lfs_objects, -> { distinct }, through: :lfs_objects_projects
  has_many :lfs_file_locks
  has_many :project_group_links
  has_many :invited_groups, through: :project_group_links, source: :group
  has_many :todos
  has_many :notification_settings, as: :source, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  has_many :internal_ids

  has_one :import_data, class_name: 'ProjectImportData', inverse_of: :project, autosave: true
  has_one :project_feature, inverse_of: :project
  has_one :statistics, class_name: 'ProjectStatistics'
  has_one :feature_usage, class_name: 'ProjectFeatureUsage'

  has_one :cluster_project, class_name: 'Clusters::Project'
  has_many :clusters, through: :cluster_project, class_name: 'Clusters::Cluster'
  has_many :kubernetes_namespaces, class_name: 'Clusters::KubernetesNamespace'
  has_many :management_clusters, class_name: 'Clusters::Cluster', foreign_key: :management_project_id, inverse_of: :management_project
  has_many :cluster_agents, class_name: 'Clusters::Agent'
  has_many :ci_access_project_authorizations, class_name: 'Clusters::Agents::Authorizations::CiAccess::ProjectAuthorization'

  has_many :alert_management_alerts, class_name: 'AlertManagement::Alert', inverse_of: :project
  has_many :alert_management_http_integrations, class_name: 'AlertManagement::HttpIntegration', inverse_of: :project

  has_many :container_registry_protection_rules, class_name: 'ContainerRegistry::Protection::Rule', inverse_of: :project
  has_many :container_registry_protection_tag_rules, class_name: 'ContainerRegistry::Protection::TagRule', inverse_of: :project
  # Container repositories need to remove data from the container registry,
  # which is not managed by the DB. Hence we're still using dependent: :destroy
  # here.
  has_many :container_repositories, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_one :container_expiration_policy, inverse_of: :project

  has_many :commit_statuses
  # The relation :all_pipelines is intended to be used when we want to get the
  # whole list of pipelines associated to the project
  has_many :all_pipelines, class_name: 'Ci::Pipeline', inverse_of: :project
  # The relation :ci_pipelines includes all those that directly contribute to the
  # latest status of a ref. This does not include dangling pipelines such as those
  # from webide, child pipelines, etc.
  has_many :ci_pipelines, -> { ci_sources }, class_name: 'Ci::Pipeline', inverse_of: :project
  has_many :stages, class_name: 'Ci::Stage', inverse_of: :project
  has_many :ci_refs, class_name: 'Ci::Ref', inverse_of: :project
  has_many :pipeline_metadata, class_name: 'Ci::PipelineMetadata', inverse_of: :project
  has_many :pending_builds, class_name: 'Ci::PendingBuild'
  has_many :builds, class_name: 'Ci::Build', inverse_of: :project
  has_many :processables, class_name: 'Ci::Processable', inverse_of: :project
  has_many :build_trace_chunks, class_name: 'Ci::BuildTraceChunk', through: :builds, source: :trace_chunks, dependent: :restrict_with_error
  has_many :build_report_results, class_name: 'Ci::BuildReportResult', inverse_of: :project
  has_many :job_artifacts, class_name: 'Ci::JobArtifact', dependent: :restrict_with_error
  has_many :pipeline_artifacts, class_name: 'Ci::PipelineArtifact', inverse_of: :project, dependent: :restrict_with_error
  has_many :runner_projects, class_name: 'Ci::RunnerProject', inverse_of: :project
  has_many :runners, through: :runner_projects, source: :runner, class_name: 'Ci::Runner'
  has_many :variables, class_name: 'Ci::Variable'
  has_many :triggers, ->(project) { Feature.enabled?(:trigger_token_expiration, project) ? not_expired : self }, class_name: 'Ci::Trigger'
  has_many :secure_files, class_name: 'Ci::SecureFile', dependent: :restrict_with_error
  has_many :environments
  has_many :environments_for_dashboard, -> { from(with_rank.unfoldered.available, :environments).where('rank <= 3') }, class_name: 'Environment'
  has_many :deployments
  has_many :pipeline_schedules, class_name: 'Ci::PipelineSchedule'
  has_many :project_deploy_tokens
  has_many :deploy_tokens, through: :project_deploy_tokens
  has_many :resource_groups, class_name: 'Ci::ResourceGroup', inverse_of: :project
  has_many :freeze_periods, class_name: 'Ci::FreezePeriod', inverse_of: :project

  has_one :auto_devops, class_name: 'ProjectAutoDevops', inverse_of: :project, autosave: true
  has_many :custom_attributes, class_name: 'ProjectCustomAttribute'

  has_many :project_badges, class_name: 'ProjectBadge', inverse_of: :project
  has_one :ci_cd_settings, class_name: 'ProjectCiCdSetting', inverse_of: :project, autosave: true, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  has_many :remote_mirrors, inverse_of: :project
  has_many :external_pull_requests, inverse_of: :project, class_name: 'Ci::ExternalPullRequest'

  has_many :sourced_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :source_project_id
  has_many :source_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :project_id

  has_many :import_failures, inverse_of: :project
  has_many :jira_imports, -> { order(JiraImportState.arel_table[:created_at].asc) }, class_name: 'JiraImportState', inverse_of: :project

  has_many :daily_build_group_report_results, class_name: 'Ci::DailyBuildGroupReportResult'
  has_many :ci_feature_usages, class_name: 'Projects::CiFeatureUsage'

  has_many :repository_storage_moves, class_name: 'Projects::RepositoryStorageMove', inverse_of: :container

  has_many :webide_pipelines, -> { webide_source }, class_name: 'Ci::Pipeline', inverse_of: :project
  has_many :reviews, inverse_of: :project

  has_many :terraform_states, class_name: 'Terraform::State', inverse_of: :project

  # GitLab Pages
  has_many :pages_domains
  has_one  :pages_metadatum, class_name: 'ProjectPagesMetadatum', inverse_of: :project
  # rubocop:disable Cop/ActiveRecordDependent -- we need to clean up files, not only remove records
  has_many :pages_deployments, dependent: :destroy, inverse_of: :project
  # rubocop:enable Cop/ActiveRecordDependent
  has_many :active_pages_deployments, -> { active.order_by(:created_desc) }, class_name: 'PagesDeployment', inverse_of: :project

  has_many :operations_feature_flags, class_name: 'Operations::FeatureFlag'
  has_one :operations_feature_flags_client, class_name: 'Operations::FeatureFlagsClient'
  has_many :operations_feature_flags_user_lists, class_name: 'Operations::FeatureFlags::UserList'

  has_many :error_tracking_client_keys, inverse_of: :project, class_name: 'ErrorTracking::ClientKey'

  has_many :timelogs

  has_one :ci_project_mirror, class_name: 'Ci::ProjectMirror'
  has_many :sync_events, class_name: 'Projects::SyncEvent'

  has_one :build_artifacts_size_refresh, class_name: 'Projects::BuildArtifactsSizeRefresh'

  accepts_nested_attributes_for :variables, allow_destroy: true
  accepts_nested_attributes_for :project_feature, update_only: true
  accepts_nested_attributes_for :project_setting, update_only: true
  accepts_nested_attributes_for :import_data
  accepts_nested_attributes_for :auto_devops, update_only: true
  accepts_nested_attributes_for :ci_cd_settings, update_only: true
  accepts_nested_attributes_for :container_expiration_policy, update_only: true

  accepts_nested_attributes_for :remote_mirrors,
    allow_destroy: true,
    reject_if: ->(attrs) { attrs[:id].blank? && attrs[:url].blank? }

  accepts_nested_attributes_for :incident_management_setting, update_only: true
  accepts_nested_attributes_for :error_tracking_setting, update_only: true
  accepts_nested_attributes_for :grafana_integration, update_only: true, allow_destroy: true
  accepts_nested_attributes_for :prometheus_integration, update_only: true
  accepts_nested_attributes_for :alerting_setting, update_only: true

  delegate :merge_requests_access_level, :forking_access_level, :issues_access_level, :wiki_access_level, :snippets_access_level, :builds_access_level, :repository_access_level, :package_registry_access_level, :pages_access_level, :metrics_dashboard_access_level, :analytics_access_level, :operations_access_level, :security_and_compliance_access_level, :container_registry_access_level, :environments_access_level, :feature_flags_access_level, :monitor_access_level, :releases_access_level, :infrastructure_access_level, :model_experiments_access_level, :model_registry_access_level, to: :project_feature, allow_nil: true
  delegate :name, to: :owner, allow_nil: true, prefix: true
  delegate :jira_dvcs_server_last_sync_at, to: :feature_usage
  delegate :last_pipeline, to: :commit, allow_nil: true
  delegate :import_user, to: :root_ancestor

  with_options to: :team do
    delegate :members, prefix: true
    delegate :add_member, :add_members, :member?
    delegate :add_guest, :add_planner, :add_reporter, :add_developer, :add_maintainer, :add_owner, :add_role
    delegate :has_user?
  end

  with_options to: :namespace do
    delegate :actual_limits, :actual_plan_name, :actual_plan, :root_ancestor, allow_nil: true
    delegate :maven_package_requests_forwarding, :pypi_package_requests_forwarding, :npm_package_requests_forwarding
  end

  with_options to: :ci_cd_settings, allow_nil: true do
    delegate :group_runners_enabled, :group_runners_enabled=
    delegate :keep_latest_artifact, :keep_latest_artifact=
    delegate :restrict_user_defined_variables, :restrict_user_defined_variables=
    delegate :runner_token_expiration_interval, :runner_token_expiration_interval=, :runner_token_expiration_interval_human_readable, :runner_token_expiration_interval_human_readable=
    delegate :job_token_scope_enabled, :job_token_scope_enabled=, prefix: :ci_outbound

    with_options prefix: :ci do
      delegate :pipeline_variables_minimum_override_role, :pipeline_variables_minimum_override_role=
      delegate :push_repository_for_job_token_allowed, :push_repository_for_job_token_allowed=
      delegate :default_git_depth, :default_git_depth=
      delegate :forward_deployment_enabled, :forward_deployment_enabled=
      delegate :forward_deployment_rollback_allowed, :forward_deployment_rollback_allowed=
      delegate :inbound_job_token_scope_enabled, :inbound_job_token_scope_enabled=
      delegate :allow_fork_pipelines_to_run_in_parent_project, :allow_fork_pipelines_to_run_in_parent_project=
      delegate :separated_caches, :separated_caches=
      delegate :id_token_sub_claim_components, :id_token_sub_claim_components=
      delegate :delete_pipelines_in_seconds, :delete_pipelines_in_seconds=
    end
  end

  with_options to: :project_setting do
    delegate :allow_merge_on_skipped_pipeline, :allow_merge_on_skipped_pipeline?, :allow_merge_on_skipped_pipeline=
    delegate :allow_merge_without_pipeline, :allow_merge_without_pipeline?, :allow_merge_without_pipeline=
    delegate :has_confluence?
    delegate :show_diff_preview_in_email, :show_diff_preview_in_email=, :show_diff_preview_in_email?
    delegate :runner_registration_enabled, :runner_registration_enabled=, :runner_registration_enabled?
    delegate :emails_enabled, :emails_enabled=, :emails_enabled?
    delegate :squash_always?, :squash_never?, :squash_enabled_by_default?, :squash_readonly?
    delegate :mr_default_target_self, :mr_default_target_self=
    delegate :previous_default_branch, :previous_default_branch=
    delegate :squash_option, :squash_option=

    with_options allow_nil: true do
      delegate :merge_commit_template, :merge_commit_template=
      delegate :squash_commit_template, :squash_commit_template=
      delegate :issue_branch_template, :issue_branch_template=
      delegate :show_default_award_emojis, :show_default_award_emojis=
      delegate :enforce_auth_checks_on_uploads, :enforce_auth_checks_on_uploads=
      delegate :warn_about_potentially_unwanted_characters, :warn_about_potentially_unwanted_characters=
      delegate :duo_features_enabled, :duo_features_enabled=
    end
  end

  # Validations
  validates :creator, presence: true, on: :create
  validates :description, length: { maximum: 2000 }, allow_blank: true
  validates :ci_config_path,
    format: { without: %r{(\.{2}|\A/)},
              message: N_('cannot include leading slash or directory traversal.') },
    length: { maximum: 255 },
    allow_blank: true
  validates :name,
    presence: true,
    length: { maximum: 255 }
  validates :path,
    presence: true,
    project_path: true,
    length: { maximum: 255 }

  validates :name,
    format: { with: Gitlab::Regex.project_name_regex,
              message: Gitlab::Regex.project_name_regex_message },
    if: :name_changed?
  validates :path,
    format: { with: Gitlab::Regex.oci_repository_path_regex,
              message: Gitlab::Regex.oci_repository_path_regex_message },
    if: :path_changed?

  validates :project_feature, presence: true
  validates :namespace, presence: true
  validates :organization, presence: true
  validates :project_namespace, presence: true, on: :create, if: -> { self.namespace }
  validates :project_namespace, presence: true, on: :update, if: -> { self.project_namespace_id_changed?(to: nil) }
  validates :name, uniqueness: { scope: :namespace_id }
  validates :import_url, public_url: { schemes: ->(project) { project.persisted? ? VALID_MIRROR_PROTOCOLS : VALID_IMPORT_PROTOCOLS },
                                       ports: ->(project) { project.persisted? ? VALID_MIRROR_PORTS : VALID_IMPORT_PORTS },
                                       enforce_user: true }, if: [:external_import?, :import_url_changed?]
  validates :star_count, numericality: { greater_than_or_equal_to: 0 }
  validate :check_personal_projects_limit, on: :create
  validate :check_repository_path_availability, on: :update, if: ->(project) { project.renamed? }
  validate :visibility_level_allowed_by_group, if: :should_validate_visibility_level?
  validate :visibility_level_allowed_as_fork, if: :should_validate_visibility_level?
  validate :validate_pages_https_only, if: -> { changes.has_key?(:pages_https_only) }
  validate :changing_shared_runners_enabled_is_allowed
  validate :parent_organization_match
  validates :repository_storage, presence: true, inclusion: { in: ->(_) { Gitlab.config.repositories.storages.keys } }
  validates :variables, nested_attributes_duplicates: { scope: :environment_scope }
  validates :bfg_object_map, file_size: { maximum: :max_attachment_size }
  validates :max_artifacts_size, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validates :suggestion_commit_message, length: { maximum: MAX_SUGGESTIONS_TEMPLATE_LENGTH }

  validate :path_availability, if: :path_changed?

  # Scopes
  scope :pending_delete, -> { where(pending_delete: true) }
  scope :without_deleted, -> { where(pending_delete: false) }
  scope :not_hidden, -> { where(hidden: false) }
  scope :not_in_groups, ->(groups) { where.not(group: groups) }
  scope :by_not_in_root_id, ->(root_id) { joins(:project_namespace).where('namespaces.traversal_ids[1] NOT IN (?)', root_id) }
  scope :not_aimed_for_deletion, -> { where(marked_for_deletion_at: nil).without_deleted }

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

  scope :sorted_by_activity, -> { reorder(self.arel_table['last_activity_at'].desc) }
  scope :sorted_by_updated_asc, -> { reorder(self.arel_table['last_activity_at'].asc) }
  scope :sorted_by_updated_desc, -> { reorder(self.arel_table['last_activity_at'].desc) }
  scope :sorted_by_stars_desc, -> { reorder(self.arel_table['star_count'].desc) }
  scope :sorted_by_stars_asc, -> { reorder(self.arel_table['star_count'].asc) }
  scope :sorted_by_path_asc, -> { reorder(self.arel_table['path'].asc) }
  scope :sorted_by_path_desc, -> { reorder(self.arel_table['path'].desc) }
  # Sometimes queries (e.g. using CTEs) require explicit disambiguation with table name
  scope :projects_order_id_asc, -> { reorder(self.arel_table['id'].asc) }
  scope :projects_order_id_desc, -> { reorder(self.arel_table['id'].desc) }
  scope :sorted_by_storage_size_asc, -> { order_by_storage_size(:asc) }
  scope :sorted_by_storage_size_desc, -> { order_by_storage_size(:desc) }
  scope :order_by_storage_size, ->(direction) do
    build_keyset_order_on_joined_column(
      scope: joins(:statistics),
      attribute_name: 'project_statistics_storage_size',
      column: ::ProjectStatistics.arel_table[:storage_size],
      direction: direction,
      nullable: :nulls_first
    )
  end

  scope :sorted_by_similarity_desc, ->(search, full_path_only: false) do
    rules = if full_path_only
              [{ column: arel_table["path"], multiplier: 1 }]
            else
              [
                { column: arel_table["path"], multiplier: 1 },
                { column: arel_table["name"], multiplier: 0.7 },
                { column: arel_table["description"], multiplier: 0.2 }
              ]
            end

    order_expression = Gitlab::Database::SimilarityScore.build_expression(
      search: search,
      rules: rules
    )

    order = Gitlab::Pagination::Keyset::Order.build(
      [
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'similarity',
          column_expression: order_expression,
          order_expression: order_expression.desc,
          order_direction: :desc,
          add_to_projections: true
        ),
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'id',
          order_expression: Project.arel_table[:id].desc
        )
      ])

    order.apply_cursor_conditions(reorder(order))
  end

  scope :with_packages, -> { joins(:packages) }
  scope :in_namespace, ->(namespace_ids) { where(namespace_id: namespace_ids) }
  scope :personal, ->(user) { where(namespace_id: user.namespace_id) }
  scope :joined, ->(user) { where.not(namespace_id: user.namespace_id) }
  scope :starred_by, ->(user) { joins(:users_star_projects).where('users_star_projects.user_id': user.id) }
  scope :visible_to_user, ->(user) { where(id: user.authorized_projects.select(:id).reorder(nil)) }
  scope :visible_to_user_and_access_level, ->(user, access_level) { where(id: user.authorized_projects.where('project_authorizations.access_level >= ?', access_level).select(:id).reorder(nil)) }
  scope :archived, -> { where(archived: true) }
  scope :non_archived, -> { where(archived: false) }
  scope :with_push, -> { joins(:events).merge(Event.pushed_action) }
  scope :with_project_feature, -> { joins('LEFT JOIN project_features ON projects.id = project_features.project_id') }
  scope :with_jira_dvcs_server, -> { joins(:feature_usage).merge(ProjectFeatureUsage.with_jira_dvcs_integration_enabled(cloud: false)) }
  scope :by_name, ->(name) { where('projects.name LIKE ?', "#{sanitize_sql_like(name)}%") }
  scope :inc_routes, -> { includes(:route, namespace: :route) }
  scope :include_fork_networks, -> { includes(:fork_network) }
  scope :with_statistics, -> { includes(:statistics) }
  scope :with_namespace, -> { includes(:namespace) }
  scope :joins_namespace, -> { joins(:namespace) }
  scope :with_group, -> { includes(:group) }
  scope :with_import_state, -> { includes(:import_state) }
  scope :include_project_feature, -> { includes(:project_feature) }
  scope :include_integration, ->(integration_association_name) { includes(integration_association_name) }
  scope :with_integration, ->(integration_class) { joins(:integrations).merge(integration_class.all) }
  scope :with_active_integration, ->(integration_class) { with_integration(integration_class).merge(integration_class.active) }
  scope :with_shared_runners_enabled, -> { where(shared_runners_enabled: true) }
  # .with_slack_integration can generate poorly performing queries. It is intended only for UsagePing.
  scope :with_slack_integration, -> { joins(:slack_integration) }
  # .with_slack_slash_commands_integration can generate poorly performing queries. It is intended only for UsagePing.
  scope :with_slack_slash_commands_integration, -> { joins(:slack_slash_commands_integration) }
  scope :inside_path, ->(path) do
    # We need routes alias rs for JOIN so it does not conflict with
    # includes(:route) which we use in ProjectsFinder.
    joins("INNER JOIN routes rs ON rs.source_id = projects.id AND rs.source_type = 'Project'")
      .where('rs.path LIKE ?', "#{sanitize_sql_like(path)}/%")
      .allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/421843')
  end

  scope :with_jira_installation, ->(installation_id) do
    joins(namespace: :jira_connect_subscriptions)
    .where(jira_connect_subscriptions: { jira_connect_installation_id: installation_id })
  end

  scope :with_feature_enabled, ->(feature) {
    with_project_feature.merge(ProjectFeature.with_feature_enabled(feature))
  }

  scope :with_feature_access_level, ->(feature, level) {
    with_project_feature.merge(ProjectFeature.with_feature_access_level(feature, level))
  }

  # Picks projects which use the given programming language
  scope :with_programming_language, ->(language_name) do
    lang_id_query = ProgrammingLanguage
        .with_name_case_insensitive(language_name)
        .select(:id)

    joins(:repository_languages)
        .where(repository_languages: { programming_language_id: lang_id_query })
  end

  scope :with_programming_language_id, ->(language_id) do
    joins(:repository_languages)
        .where(repository_languages: { programming_language_id: language_id })
  end

  scope :service_desk_enabled, -> { where(service_desk_enabled: true) }
  scope :with_builds_enabled, -> { with_feature_enabled(:builds) }
  scope :with_issues_enabled, -> { with_feature_enabled(:issues) }
  scope :with_package_registry_enabled, -> { with_feature_enabled(:package_registry) }
  scope :with_public_package_registry, -> do
    where_exists(
      ::ProjectFeature
        .where(::ProjectFeature.arel_table[:project_id].eq(arel_table[:id]))
        .with_feature_access_level(:package_registry, ::ProjectFeature::PUBLIC)
    )
  end
  scope :with_issues_available_for_user, ->(current_user) { with_feature_available_for_user(:issues, current_user) }
  scope :with_merge_requests_available_for_user, ->(current_user) { with_feature_available_for_user(:merge_requests, current_user) }
  scope :with_issues_or_mrs_available_for_user, ->(user) do
    with_issues_available_for_user(user).or(with_merge_requests_available_for_user(user))
  end
  scope :with_merge_requests_enabled, -> { with_feature_enabled(:merge_requests) }
  scope :with_remote_mirrors, -> { joins(:remote_mirrors).where(remote_mirrors: { enabled: true }) }
  scope :with_limit, ->(maximum) { limit(maximum) }

  scope :with_group_runners_enabled, -> do
    joins(:ci_cd_settings)
    .where(project_ci_cd_settings: { group_runners_enabled: true })
  end

  scope :with_pages_deployed, -> do
    where_exists(PagesDeployment.active.where('pages_deployments.project_id = projects.id'))
  end

  scope :pages_metadata_not_migrated, -> do
    left_outer_joins(:pages_metadatum)
      .where(project_pages_metadata: { project_id: nil })
  end

  scope :with_namespace_domain_pages, -> do
    joins(:project_setting)
      .where(project_setting: { pages_unique_domain_enabled: false })
  end

  scope :with_api_commit_entity_associations, -> {
    preload(:project_feature, :route, namespace: [:route, :owner])
  }

  scope :with_name, ->(name) { where(name: name) }
  scope :created_by, ->(user) { where(creator: user) }
  scope :imported_from, ->(type) { where(import_type: type) }
  scope :imported, -> { where.not(import_type: nil) }
  scope :with_enabled_error_tracking, -> { joins(:error_tracking_setting).where(project_error_tracking_settings: { enabled: true }) }
  scope :last_activity_before, ->(time) { where('projects.last_activity_at < ?', time) }

  scope :with_service_desk_key, ->(key) do
    # project_key is not indexed for now
    # see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24063#note_282435524 for details
    joins(:service_desk_setting).where('service_desk_settings.project_key' => key)
  end

  scope :with_topic, ->(topic) { where(id: topic.project_topics.select(:project_id)) }

  scope :with_topic_by_name, ->(topic_name) do
    topic = Projects::Topic.find_by_name(topic_name)

    topic ? with_topic(topic) : none
  end

  scope :pending_data_repair_analysis, -> do
    left_outer_joins(:container_registry_data_repair_detail)
    .where(container_registry_data_repair_details: { project_id: nil })
    .order(id: :desc)
  end

  scope :in_organization, ->(organization) { where(organization: organization) }
  scope :by_project_namespace, ->(project_namespace) { where(project_namespace_id: project_namespace) }
  scope :by_any_overlap_with_traversal_ids, ->(traversal_ids) {
    joins_namespace.where('namespaces.traversal_ids::bigint[] && ARRAY[?]::bigint[]', traversal_ids)
  }

  scope :not_a_fork, -> {
    left_outer_joins(:fork_network_member).where(fork_network_member: { forked_from_project_id: nil })
  }

  enum auto_cancel_pending_pipelines: { disabled: 0, enabled: 1 }

  chronic_duration_attr :build_timeout_human_readable, :build_timeout,
    default: 3600, error_message: N_('Maximum job timeout has a value which could not be accepted')

  validates :build_timeout, allow_nil: true, numericality: {
    greater_than_or_equal_to: 10.minutes,
    less_than: MAX_BUILD_TIMEOUT,
    only_integer: true,
    message: N_('needs to be between 10 minutes and 1 month')
  }

  # Used by Projects::CleanupService to hold a map of rewritten object IDs
  mount_uploader :bfg_object_map, AttachmentUploader

  def self.with_api_entity_associations
    preload(:project_feature, :route, :topics, :group, :timelogs, namespace: [:route, :owner])
  end

  def self.with_web_entity_associations
    preload(:project_feature, :route, :creator, group: :parent, namespace: [:route, :owner])
  end

  def self.with_slack_application_disabled
    # Using Arel to avoid exposing what the column backing the type: attribute is
    # rubocop: disable GitlabSecurity/PublicSend
    with_active_slack = Integration.active.by_name(:gitlab_slack_application)
    join_contraint = arel_table[:id].eq(Integration.arel_table[:project_id])
    constraint = with_active_slack.where_clause.send(:predicates).reduce(join_contraint) { |a, b| a.and(b) }
    join = arel_table.join(Integration.arel_table, Arel::Nodes::OuterJoin).on(constraint).join_sources
    # rubocop: enable GitlabSecurity/PublicSend

    joins(join).where(integrations: { id: nil })
  rescue Integration::UnknownType
    all
  end

  def self.eager_load_namespace_and_owner
    includes(namespace: :owner)
  end

  # Returns a collection of projects that is either public or visible to the
  # logged in user.
  def self.public_or_visible_to_user(user = nil, min_access_level = nil)
    min_access_level = nil if user&.can_read_all_resources?

    return public_to_user unless user

    if user.is_a?(DeployToken)
      where(id: user.accessible_projects)
    else
      where(
        'EXISTS (?) OR projects.visibility_level IN (?)',
        user.authorizations_for_projects(min_access_level: min_access_level),
        Gitlab::VisibilityLevel.levels_for_user(user)
      )
    end
  end

  # Define two instance methods:
  #
  # - [attribute]?(inherit_group_setting) Returns the final value after inheriting the parent group
  # - [attribute]_locked?                 Returns true if the value is inherited from the parent group
  #
  # These functions will be overridden in EE to make sense afterwards
  def self.cascading_with_parent_namespace(attribute)
    define_method("#{attribute}?") do |inherit_group_setting: false|
      self.public_send(attribute) # rubocop:disable GitlabSecurity/PublicSend
    end

    define_method("#{attribute}_locked?") do
      false
    end
  end

  cascading_with_parent_namespace :only_allow_merge_if_pipeline_succeeds
  cascading_with_parent_namespace :allow_merge_on_skipped_pipeline
  cascading_with_parent_namespace :only_allow_merge_if_all_discussions_are_resolved
  cascading_with_parent_namespace :allow_merge_without_pipeline

  def self.with_feature_available_for_user(feature, user)
    with_project_feature.merge(ProjectFeature.with_feature_available_for_user(feature, user))
  end

  def self.projects_user_can(projects, user, action)
    DeclarativePolicy.user_scope do
      projects.select { |project| Ability.allowed?(user, action, project) }
    end
  end

  def self.filter_out_public_projects_with_unauthorized_private_repos(projects, user)
    public_projects_with_private_repos = projects.with_project_feature.where(
      visibility_level: Gitlab::VisibilityLevel::PUBLIC,
      project_features: { repository_access_level: ProjectFeature::PRIVATE }
    ).pluck(:id)

    return projects unless public_projects_with_private_repos.present?

    authorized_public_projects_with_private_repos = projects.filter_by_feature_visibility(
      :repository, user
    )

    rejected_projects_with_private_repos = (
      public_projects_with_private_repos - authorized_public_projects_with_private_repos.pluck(:id)
    )

    projects.where.not(id: rejected_projects_with_private_repos)
  end

  # This scope returns projects where user has access to both the project and the feature.
  def self.filter_by_feature_visibility(feature, user)
    with_feature_available_for_user(feature, user)
      .public_or_visible_to_user(
        user,
        ProjectFeature.required_minimum_access_level_for_private_project(feature)
      )
  end

  def self.wrap_with_cte(collection)
    cte = Gitlab::SQL::CTE.new(:projects_cte, collection)
    Project.with(cte.to_arel).from(cte.alias_to(Project.arel_table))
  end

  def self.inactive
    project_statistics = ::ProjectStatistics.arel_table
    minimum_size_mb = ::Gitlab::CurrentSettings.inactive_projects_min_size_mb.megabytes
    last_activity_cutoff = ::Gitlab::CurrentSettings.inactive_projects_send_warning_email_after_months.months.ago

    joins(:statistics)
      .where((project_statistics[:storage_size]).gt(minimum_size_mb))
      .where('last_activity_at < ?', last_activity_cutoff)
  end

  scope :active, -> { joins(:issues, :notes, :merge_requests).order('issues.created_at, notes.created_at, merge_requests.created_at DESC') }
  scope :abandoned, -> { where('projects.last_activity_at < ?', 6.months.ago) }

  scope :excluding_project, ->(project) { where.not(id: project) }

  # We require an alias to the project_mirror_data_table in order to use import_state in our queries
  scope :joins_import_state, -> { joins("INNER JOIN project_mirror_data import_state ON import_state.project_id = projects.id") }
  scope :for_group, ->(group) { where(group: group) }
  scope :for_group_and_its_subgroups, ->(group) { where(namespace_id: group.self_and_descendants.select(:id)) }
  scope :for_group_and_its_ancestor_groups, ->(group) { where(namespace_id: group.self_and_ancestors.select(:id)) }
  scope :is_importing, -> { with_import_state.where(import_state: { status: %w[started scheduled] }) }

  scope :without_created_and_owned_by_banned_user, -> do
    where_not_exists(
      Users::BannedUser.joins(
        'INNER JOIN project_authorizations ON project_authorizations.user_id = banned_users.user_id'
      ).where('projects.creator_id = banned_users.user_id')
        .where('project_authorizations.project_id = projects.id')
        .where(project_authorizations: { access_level: Gitlab::Access::OWNER })
    )
  end

  class << self
    # Searches for a list of projects based on the query given in `query`.
    #
    # On PostgreSQL this method uses "ILIKE" to perform a case-insensitive
    # search.
    #
    # query - The search query as a String.
    def search(query, include_namespace: false, use_minimum_char_limit: true)
      if include_namespace
        joins(:route).fuzzy_search(query, [Route.arel_table[:path], Route.arel_table[:name], :description],
          use_minimum_char_limit: use_minimum_char_limit)
        .allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/421843')
      else
        fuzzy_search(query, [:path, :name, :description], use_minimum_char_limit: use_minimum_char_limit)
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
      when 'storage_size_asc'
        sorted_by_storage_size_asc
      when 'storage_size_desc'
        sorted_by_storage_size_desc
      when 'latest_activity_desc'
        sorted_by_updated_desc
      when 'latest_activity_asc'
        sorted_by_updated_asc
      when 'path_asc'
        sorted_by_path_asc
      when 'path_desc'
        sorted_by_path_desc
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
        (?<absolute_path>/)?
        ((?<namespace>#{Gitlab::PathRegex::FULL_NAMESPACE_FORMAT_REGEX})/)?
        (?<project>#{Gitlab::PathRegex::PROJECT_PATH_FORMAT_REGEX})
      }xo
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
      @markdown_reference_pattern ||=
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
      joins(:namespace).where(namespaces: { type: Group.sti_name }).select(:namespace_id)
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

    def find_by_url(url)
      uri = URI(url)

      return unless uri.host == Gitlab.config.gitlab.host

      match = Rails.application.routes.recognize_path(url)

      return if match[:unmatched_route].present?
      return if match[:namespace_id].blank? || match[:id].blank?

      find_by_full_path(match.values_at(:namespace_id, :id).join("/"))
    rescue ActionController::RoutingError, URI::InvalidURIError
      nil
    end

    def without_integration(integration)
      integrations = Integration
        .select('1')
        .where("#{Integration.table_name}.project_id = projects.id")
        .where(type: integration.type)

      Project
        .where('NOT EXISTS (?)', integrations)
        .where(pending_delete: false)
        .where(archived: false)
    end

    def project_features_defaults
      PROJECT_FEATURES_DEFAULTS
    end

    def by_pages_enabled_unique_domain(domain)
      without_deleted
        .joins(:project_setting)
        .find_by(project_setting: {
          pages_unique_domain_enabled: true,
          pages_unique_domain: domain
        })
    end
  end

  def initialize(attributes = nil)
    # We assign the actual snippet default if no explicit visibility has been initialized.
    attributes ||= {}

    unless visibility_attribute_present?(attributes)
      attributes[:visibility_level] = Gitlab::CurrentSettings.default_project_visibility
    end

    @init_attributes = attributes

    super
  end

  # Remove along with ProjectFeaturesCompatibility module
  def set_project_feature_defaults
    self.class.project_features_defaults.each do |attr, value|
      # If the deprecated _enabled or the accepted _access_level attribute is specified, we don't need to set the default
      next unless @init_attributes[:"#{attr}_enabled"].nil? && @init_attributes[:"#{attr}_access_level"].nil?

      public_send("#{attr}_enabled=", value) # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  def parent_loaded?
    association(:namespace).loaded?
  end

  def certificate_based_clusters_enabled?
    !!namespace&.certificate_based_clusters_enabled?
  end

  def prometheus_integration_active?
    !!prometheus_integration&.active?
  end

  def jenkins_integration_active?
    !!jenkins_integration&.active?
  end

  def personal_namespace_holder?(user)
    return false unless personal?
    return false unless user

    # We do not want to use a check like `project.team.owner?(user)`
    # here because that would depend upon the state of the `project_authorizations` cache,
    # and also perform the check across multiple `owners` of the project, but our intention
    # is to check if the user is the "holder" of the personal namespace, so need to make this
    # check against only a single user (ie, namespace.owner).
    namespace.owner == user
  end

  def invalidate_personal_projects_count_of_owner
    return unless personal?
    return unless namespace.owner

    namespace.owner.invalidate_personal_projects_count
  end

  def project_setting
    super.presence || build_project_setting
  end

  def show_default_award_emojis?
    !!project_setting&.show_default_award_emojis?
  end

  def enforce_auth_checks_on_uploads?
    !!project_setting&.enforce_auth_checks_on_uploads?
  end

  def warn_about_potentially_unwanted_characters?
    !!project_setting&.warn_about_potentially_unwanted_characters?
  end

  def no_import?
    !!import_state&.no_import?
  end

  def import_scheduled?
    !!import_state&.scheduled?
  end

  def import_started?
    !!import_state&.started?
  end

  def import_in_progress?
    !!import_state&.in_progress?
  end

  def import_failed?
    !!import_state&.failed?
  end

  def import_finished?
    !!import_state&.finished?
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

  def active_webide_pipelines(user:)
    webide_pipelines.running_or_pending.for_user(user)
  end

  def default_pipeline_lock
    if keep_latest_artifacts_available?
      return :artifacts_locked
    end

    :unlocked
  end

  def autoclose_referenced_issues
    return true if super.nil?

    super
  end

  def preload_protected_branches
    ActiveRecord::Associations::Preloader.new(
      records: [all_protected_branches, protected_branches].flatten,
      associations: [:push_access_levels, :merge_access_levels]
    ).call
  end

  # returns all ancestor-groups upto but excluding the given namespace
  # when no namespace is given, all ancestors upto the top are returned
  def ancestors_upto(top = nil, hierarchy_order: nil)
    Gitlab::ObjectHierarchy.new(Group.where(id: namespace_id))
      .base_and_ancestors(upto: top, hierarchy_order: hierarchy_order)
  end

  def ancestors(hierarchy_order: nil)
    group&.self_and_ancestors(hierarchy_order: hierarchy_order) || Group.none
  end

  def ancestors_upto_ids(...)
    ancestors_upto(...).pluck(:id)
  end

  def emails_disabled?
    # disabling in the namespace overrides the project setting
    !emails_enabled?
  end

  override :lfs_enabled?
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

  def packages_cleanup_policy
    super || build_packages_cleanup_policy
  end

  def first_auto_devops_config
    return namespace.first_auto_devops_config if auto_devops&.enabled.nil?

    { scope: :project, status: auto_devops&.enabled || Feature.enabled?(:force_autodevops_on_by_default, self) }
  end

  # LFS and hashed repository storage are required for using Design Management.
  def design_management_enabled?
    lfs_enabled? && hashed_storage?(:repository)
  end

  def team
    @team ||= ProjectTeam.new(self)
  end

  def repository
    @repository ||= Gitlab::GlRepository::PROJECT.repository_for(self)
  end

  def find_or_create_design_management_repository
    design_management_repository || create_design_management_repository
  end

  def design_repository
    strong_memoize(:design_repository) do
      find_or_create_design_management_repository.repository
    end
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

  def container_repositories_size
    strong_memoize(:container_repositories_size) do
      next 0 if container_repositories.empty?
      next unless ContainerRegistry::GitlabApiClient.supports_gitlab_api?

      ContainerRegistry::GitlabApiClient.deduplicated_size(full_path)
    end
  end

  def has_container_registry_tags?
    return @images if defined?(@images)

    @images = container_repositories.to_a.any?(&:has_tags?) ||
      has_root_container_repository_tags?
  end

  # ref can't be HEAD, can only be branch/tag name
  def latest_successful_build_for_ref(job_name, ref = default_branch)
    return unless ref

    latest_pipeline = ci_pipelines.latest_successful_for_ref(ref)
    return unless latest_pipeline

    latest_pipeline.build_with_artifacts_in_self_and_project_descendants(job_name)
  end

  def latest_successful_build_for_sha(job_name, sha)
    return unless sha

    latest_pipeline = ci_pipelines.latest_successful_for_sha(sha)
    return unless latest_pipeline

    latest_pipeline.build_with_artifacts_in_self_and_project_descendants(job_name)
  end

  def latest_successful_build_for_ref!(job_name, ref = default_branch)
    latest_successful_build_for_ref(job_name, ref) || raise(ActiveRecord::RecordNotFound, "Couldn't find job #{job_name}")
  end

  def latest_pipelines(ref: default_branch, sha: nil, limit: nil)
    ref = ref.presence || default_branch
    sha ||= commit(ref)&.sha
    return ci_pipelines.none unless sha

    ci_pipelines.newest_first(ref: ref, sha: sha, limit: limit)
  end

  def latest_pipeline(ref = default_branch, sha = nil)
    latest_pipelines(ref: ref, sha: sha).take
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

  def import_checksums
    import_state&.checksums || {}
  end

  def jira_import_status
    latest_jira_import&.status || 'initial'
  end

  def human_import_status_name
    import_state&.human_status_name || 'none'
  end

  def beautified_import_status_name
    if import_finished?
      return 'completed' unless import_checksums.present?

      fetched = import_checksums['fetched']
      imported = import_checksums['imported']
      fetched.keys.any? { |key| fetched[key] != imported[key] } ? 'partially completed' : 'completed'
    else
      import_status
    end
  end

  def add_import_job
    job_id =
      if forked?
        RepositoryForkWorker.perform_async(id)
      else
        RepositoryImportWorker.perform_async(self.id)
      end

    log_import_activity(job_id)

    job_id
  end

  def log_import_activity(job_id, type: :import)
    job_type = type.to_s.capitalize

    if job_id
      use_primary = ::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer).use_primary?
      Gitlab::AppLogger.info("#{job_type} job scheduled for #{full_path} with job ID #{job_id} (primary: #{use_primary}).")
    else
      Gitlab::AppLogger.error("#{job_type} job failed to create for #{full_path}.")
    end
  end

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

  # Used by Import/Export to export commit notes
  def commit_notes
    notes.where(noteable_type: "Commit")
  end

  def import_url=(value)
    if Gitlab::UrlSanitizer.valid?(value)
      import_url = Gitlab::UrlSanitizer.new(value)
      super(import_url.sanitized_url)

      credentials = import_url.credentials.to_h.transform_values { |value| CGI.unescape(value.to_s) }
      build_or_assign_import_data(credentials: credentials)
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
  rescue StandardError
    super
  end

  def valid_import_url?
    valid?(:import_url) || errors.messages[:import_url].nil?
  end

  def build_or_assign_import_data(data: nil, credentials: nil)
    project_import_data = import_data || build_import_data

    project_import_data.merge_data(data.to_h) if data
    project_import_data.merge_credentials(credentials.to_h) if credentials

    project_import_data
  end

  def import?
    external_import? || forked? || gitlab_project_import? || jira_import? || gitlab_project_migration?
  end

  def external_import?
    import_url.present?
  end

  def notify_project_import_complete?
    return false if import_type.nil? || mirror? || forked?

    gitea_import? || github_import? || bitbucket_import? || bitbucket_server_import?
  end

  def safe_import_url(masked: true)
    url = Gitlab::UrlSanitizer.new(import_url)
    masked ? url.masked_url : url.sanitized_url
  end

  def jira_import?
    import_type == 'jira' && latest_jira_import.present?
  end

  def gitlab_project_import?
    import_type == 'gitlab_project'
  end

  def gitlab_project_migration?
    import_type == 'gitlab_project_migration'
  end

  def gitea_import?
    import_type == 'gitea'
  end

  def github_import?
    import_type == 'github'
  end

  def bitbucket_import?
    import_type == 'bitbucket'
  end

  def bitbucket_server_import?
    import_type == 'bitbucket_server'
  end

  def github_enterprise_import?
    github_import? &&
      URI.parse(import_url).host != URI.parse(Octokit::Default::API_ENDPOINT).host
  end

  # Determine whether any kind of import is in progress.
  # - Full file import
  # - Relation import
  # - Direct Transfer
  def any_import_in_progress?
    relation_import_trackers.last&.started? ||
      import_started? ||
      BulkImports::Entity.with_status(:started).where(project_id: id).any?
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
      last_update_at: Time.current
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
      if limit == 0
        _('You cannot create projects in your personal namespace. Contact your GitLab administrator.')
      else
        _("You've reached your limit of %{limit} projects created. Contact your GitLab administrator.")
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

  def changing_shared_runners_enabled_is_allowed
    return unless new_record? || changes.has_key?(:shared_runners_enabled)

    if shared_runners_setting_conflicting_with_group?
      errors.add(:shared_runners_enabled, _('cannot be enabled because parent group does not allow it'))
    end
  end

  def parent_organization_match
    return unless parent
    return if parent.organization_id == organization_id

    errors.add(:organization_id, _("must match the parent organization's ID"))
  end

  def shared_runners_setting_conflicting_with_group?
    shared_runners_enabled && group&.shared_runners_setting == Namespace::SR_DISABLED_AND_UNOVERRIDABLE
  end

  def reconcile_shared_runners_setting!
    if shared_runners_setting_conflicting_with_group?
      self.shared_runners_enabled = false
    end
  end

  def to_param
    if persisted? && errors.include?(:path)
      path_was
    else
      path
    end
  end

  # Produce a valid reference (see Referable#to_reference)
  #
  # NB: For projects, all references are 'full' - i.e. they all include the
  # full_path, rather than just the project name. For this reason, we ignore
  # the value of `full:` passed to this method, which is part of the Referable
  # interface.
  def to_reference(from = nil, full: false)
    base = to_reference_base(from, full: true)
    "#{base}#{self.class.reference_postfix}"
  end

  # `from` argument can be a Namespace or Project.
  def to_reference_base(from = nil, full: false, absolute_path: false)
    if full || cross_namespace_reference?(from)
      absolute_path ? "/#{full_path}" : full_path
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

  def readme_url
    readme_path = repository.readme_path
    if readme_path
      Gitlab::Routing.url_helpers.project_blob_url(self, File.join(default_branch, readme_path))
    end
  end

  def new_issuable_address(author, address_type)
    return unless Gitlab::Email::IncomingEmail.supports_issue_creation? && author

    # check since this can come from a request parameter
    return unless %w[issue merge_request].include?(address_type)

    author.ensure_incoming_email_token!

    suffix = address_type.dasherize

    # example: incoming+h5bp-html5-boilerplate-8-1234567890abcdef123456789-issue@localhost.com
    # example: incoming+h5bp-html5-boilerplate-8-1234567890abcdef123456789-merge-request@localhost.com
    Gitlab::Email::IncomingEmail.reply_address("#{full_path_slug}-#{project_id}-#{author.incoming_email_token}-#{suffix}")
  end

  def build_commit_note(commit)
    notes.new(commit_id: commit.id, noteable_type: 'Commit')
  end

  def last_activity
    last_event
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

  def external_issue_reference_pattern
    external_issue_tracker.reference_pattern(only_long: issues_enabled?)
  end

  def default_issues_tracker?
    !external_issue_tracker
  end

  def external_issue_tracker
    cache_has_external_issue_tracker if has_external_issue_tracker.nil?

    return unless has_external_issue_tracker?

    @external_issue_tracker ||= integrations.external_issue_trackers.first
  end

  def external_references_supported?
    external_issue_tracker&.support_cross_reference?
  end

  def has_wiki?
    wiki_enabled? || has_external_wiki?
  end

  def external_wiki
    cache_has_external_wiki if has_external_wiki.nil?

    return unless has_external_wiki?

    @external_wiki ||= integrations.external_wikis.first
  end

  def find_or_initialize_integrations
    Integration
      .available_integration_names(include_instance_specific: false)
      .difference(disabled_integrations)
      .map { find_or_initialize_integration(_1) }
      .sort_by { |int| int.title.downcase }
  end

  # Returns a list of integration names that should be disabled at the project-level.
  # Globally disabled integrations should go in Integration.disabled_integration_names.
  def disabled_integrations
    return [] if Rails.env.development?

    %w[zentao]
  end

  def find_or_initialize_integration(name)
    return if disabled_integrations.include?(name)
    return if Integration.available_integration_names(include_instance_specific: false).exclude?(name)

    find_integration(integrations, name) || build_from_instance(name) || build_integration(name)
  end

  # rubocop: disable CodeReuse/ServiceClass
  def create_labels
    Label.templates.each do |label|
      # slice on column_names to ensure an added DB column will not break a mixed deployment
      params = label.attributes.slice(*Label.column_names).except('id', 'template', 'created_at', 'updated_at', 'type')
      Labels::FindOrCreateService.new(nil, self, params).execute(skip_authorization: true)
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

  def ci_integrations
    integrations.where(category: :ci)
  end

  def ci_integration
    @ci_integration ||= ci_integrations.reorder(nil).find_by(active: true)
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
    group_clusters = Clusters::Cluster.joins(:groups).where(cluster_groups: { group_id: ancestors_upto })
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
    # This will be phased out and replaced with `owners` relationship
    # backed by memberships with direct/inherited Owner access roles
    # See https://gitlab.com/groups/gitlab-org/-/epics/7405
    group || namespace.try(:owner)
  end

  def deprecated_owner
    # Kept in order to maintain webhook structures until we remove owner_name and owner_email
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/350603
    group || namespace.try(:owner)
  end

  def owners
    # This will be phased out and replaced with `owners` relationship
    # backed by memberships with direct/inherited Owner access roles
    # See https://gitlab.com/groups/gitlab-org/-/epics/7405
    team.owners
  end

  def first_owner
    obj = owner

    if obj.respond_to?(:first_owner)
      obj.first_owner
    else
      obj
    end
  end

  # rubocop: disable CodeReuse/ServiceClass
  def execute_hooks(data, hooks_scope = :push_hooks)
    run_after_commit_or_now do
      triggered_hooks(hooks_scope, data).execute
      SystemHooksService.new.execute_hooks(data, hooks_scope)
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

  def triggered_hooks(hooks_scope, data)
    triggered = ::Projects::TriggeredHooks.new(hooks_scope, data)
    triggered.add_hooks(hooks)
  end

  def execute_integrations(data, hooks_scope = :push_hooks, skip_ci: false)
    # Call only service hooks that are active for this scope
    run_after_commit_or_now do
      association("#{hooks_scope}_integrations").reader.each do |integration|
        next if skip_ci && integration.ci?

        integration.async_execute(data)
      end
    end
  end

  def has_active_hooks?(hooks_scope = :push_hooks)
    @has_active_hooks ||= {} # rubocop: disable Gitlab/PredicateMemoization

    return @has_active_hooks[hooks_scope] if @has_active_hooks.key?(hooks_scope)

    @has_active_hooks[hooks_scope] = hooks.hooks_for(hooks_scope).any? ||
      SystemHook.hooks_for(hooks_scope).any? ||
      Gitlab::FileHook.any?
  end

  def has_active_integrations?(hooks_scope = :push_hooks)
    @has_active_integrations ||= {} # rubocop: disable Gitlab/PredicateMemoization

    return @has_active_integrations[hooks_scope] if @has_active_integrations.key?(hooks_scope)

    @has_active_integrations[hooks_scope] = integrations.public_send(hooks_scope).any? # rubocop:disable GitlabSecurity/PublicSend
  end

  def feature_usage
    super.presence || build_feature_usage
  end

  def forked?
    fork_network && fork_network.root_project != self
  end

  def fork_source
    return unless forked?

    forked_from_project || fork_network&.root_project
  end

  def lfs_objects_for_repository_types(*types)
    LfsObject
      .joins(:lfs_objects_projects)
      .where(lfs_objects_projects: { project: self, repository_type: types })
  end

  def lfs_objects_oids(oids: [])
    oids(lfs_objects, oids: oids)
  end

  def lfs_objects_oids_from_fork_source(oids: [])
    return [] unless forked?

    oids(fork_source.lfs_objects, oids: oids)
  end

  def personal?
    !group
  end

  # Expires various caches before a project is renamed.
  def expire_caches_before_rename(old_path)
    project_repo = Repository.new(old_path, self, shard: repository_storage)
    wiki_repo = Repository.new("#{old_path}#{Gitlab::GlRepository::WIKI.path_suffix}", self, shard: repository_storage, repo_type: Gitlab::GlRepository::WIKI)
    design_repo = Repository.new("#{old_path}#{Gitlab::GlRepository::DESIGN.path_suffix}", self, shard: repository_storage, repo_type: Gitlab::GlRepository::DESIGN)

    [project_repo, wiki_repo, design_repo].each do |repo|
      repo.before_delete if repo.exists?
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
    (project_repository || build_project_repository).tap do |proj_repo|
      attributes = { shard_name: repository_storage, disk_path: disk_path }

      object_format = repository.object_format
      attributes[:object_format] = object_format if object_format.present?

      proj_repo.update!(**attributes)
    end

    cleanup
  end

  def create_repository(force: false, default_branch: nil, object_format: nil)
    # Forked import is handled asynchronously
    return if forked? && !force

    repository.create_repository(default_branch, object_format: object_format)
    repository.after_create

    true
  rescue StandardError => e
    Gitlab::ErrorTracking.track_exception(e, project: { id: id, full_path: full_path, disk_path: disk_path })
    errors.add(:base, _('Failed to create repository'))
    false
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

  def member(user)
    if project_members.loaded?
      project_members.find { |member| member.user_id == user.id }
    else
      project_members.find_by(user_id: user)
    end
  end

  def membership_locked?
    false
  end

  def bots
    users.project_bot
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

  def visibility_level_field
    :visibility_level
  end

  override :after_repository_change_head
  def after_repository_change_head
    ProjectCacheWorker.perform_async(self.id, [], %w[commit_count])

    super
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

  # Overridden in EE
  def allowed_to_share_with_group?
    share_with_group_enabled?
  end

  def share_with_group_enabled?
    !parent.share_with_group_lock?
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

  def feature_available?(feature, user = nil)
    !!project_feature&.feature_available?(feature, user)
  end

  def builds_enabled?
    !!project_feature&.builds_enabled?
  end

  def wiki_enabled?
    !!project_feature&.wiki_enabled?
  end

  def merge_requests_enabled?
    !!project_feature&.merge_requests_enabled?
  end

  def forking_enabled?
    !!project_feature&.forking_enabled?
  end

  def issues_enabled?
    !!project_feature&.issues_enabled?
  end

  def pages_enabled?
    !!project_feature&.pages_enabled?
  end

  def analytics_enabled?
    !!project_feature&.analytics_enabled?
  end

  def snippets_enabled?
    !!project_feature&.snippets_enabled?
  end

  def public_pages?
    !!project_feature&.public_pages?
  end

  def private_pages?
    !!project_feature&.private_pages?
  end

  def operations_enabled?
    !!project_feature&.operations_enabled?
  end

  def container_registry_enabled?
    !!project_feature&.container_registry_enabled?
  end
  alias_method :container_registry_enabled, :container_registry_enabled?

  def enable_ci
    project_feature.update_attribute(:builds_access_level, ProjectFeature::ENABLED)
  end

  def shared_runners_available?
    shared_runners_enabled?
  end

  def shared_runners
    @shared_runners ||= shared_runners_enabled? ? Ci::Runner.instance_type : Ci::Runner.none
  end

  def available_shared_runners
    @available_shared_runners ||= shared_runners_available? ? shared_runners : Ci::Runner.none
  end

  def group_runners
    @group_runners ||= group_runners_enabled? ? Ci::Runner.belonging_to_parent_groups_of_project(self.id) : Ci::Runner.none
  end

  def all_runners
    Ci::Runner.from_union([runners, group_runners, shared_runners])
  end

  def all_available_runners
    Ci::Runner.from_union([runners, group_runners, available_shared_runners])
  end

  def active_runners
    strong_memoize(:active_runners) do
      all_available_runners.active
    end
  end

  def any_online_runners?(&block)
    online_runners_with_tags.any?(&block)
  end

  def valid_runners_token?(token)
    self.runners_token && ActiveSupport::SecurityUtils.secure_compare(token, self.runners_token)
  end

  # rubocop: disable CodeReuse/ServiceClass
  def open_issues_count(current_user = nil)
    return Projects::OpenIssuesCountService.new(self, current_user).count unless current_user.nil?

    BatchLoader.for(self).batch do |projects, loader|
      issues_count_per_project = ::Projects::BatchOpenIssuesCountService.new(projects).refresh_cache_and_retrieve_data

      issues_count_per_project.each do |project, count|
        loader.call(project, count)
      end
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

  # rubocop: disable CodeReuse/ServiceClass
  def open_merge_requests_count(_current_user = nil)
    BatchLoader.for(self).batch do |projects, loader|
      ::Projects::BatchOpenMergeRequestsCountService.new(projects)
        .refresh_cache_and_retrieve_data
        .each { |project, count| loader.call(project, count) }
    end
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
    return unless namespace.allow_runner_registration_token?

    ensure_runners_token!
  end

  def pages_deployed?
    active_pages_deployments.exists?
  end

  def pages_show_onboarding?
    !(pages_metadatum&.onboarding_complete || pages_deployed?)
  end

  def pages_unique_domain_enabled?
    project_setting.pages_unique_domain_enabled
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

  def mark_pages_onboarding_complete
    ensure_pages_metadatum.update!(onboarding_complete: true)
  end

  def after_import
    repository.expire_content_cache
    repository.remove_prohibited_refs
    wiki.repository.expire_content_cache

    DetectRepositoryLanguagesWorker.perform_async(id)
    ProjectCacheWorker.perform_async(self.id, [], %w[repository_size wiki_size])
    AuthorizedProjectUpdate::ProjectRecalculateWorker.perform_async(id)

    enqueue_record_project_target_platforms

    reset_counters_and_iids

    import_state&.finish
    after_create_default_branch
    join_pool_repository
    refresh_markdown_cache!
  end

  def reset_counters_and_iids
    # The import assigns iid values on its own, e.g. by re-using GitHub ids.
    # Flush existing InternalId records for this project for consistency reasons.
    # Those records are going to be recreated with the next normal creation
    # of a model instance (e.g. an Issue).
    InternalId.flush_records!(project: self)
    update_project_counter_caches
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

  def add_export_job(current_user:, after_export_strategy: nil, params: {})
    check_project_export_limit!

    params[:exported_by_admin] = current_user.can_admin_all_resources?

    job_id = Projects::ImportExport::CreateRelationExportsWorker
                 .perform_async(current_user.id, self.id, after_export_strategy, params)

    if job_id
      Gitlab::AppLogger.info "Export job started for project ID #{self.id} with job ID #{job_id}"
    else
      Gitlab::AppLogger.error "Export job failed to start for project ID #{self.id}"
    end
  end

  def import_export_shared
    @import_export_shared ||= Gitlab::ImportExport::Shared.new(self)
  end

  def export_path
    return unless namespace.present? || hashed_storage?(:repository)

    import_export_shared.archive_path
  end

  def export_status(user)
    if regeneration_in_progress?(user)
      :regeneration_in_progress
    elsif export_enqueued?(user)
      :queued
    elsif export_in_progress?(user)
      :started
    elsif export_file_exists?(user)
      :finished
    elsif export_failed?(user)
      :failed
    else
      :none
    end
  end

  def export_in_progress?(user)
    strong_memoize(:export_in_progress) do
      ::Projects::ExportJobFinder.new(self, user, { status: :started }).execute.present?
    end
  end

  def export_enqueued?(user)
    strong_memoize(:export_enqueued) do
      ::Projects::ExportJobFinder.new(self, user, { status: :queued }).execute.present?
    end
  end

  def export_failed?(user)
    strong_memoize(:export_failed) do
      ::Projects::ExportJobFinder.new(self, user, { status: :failed }).execute.present?
    end
  end

  def regeneration_in_progress?(user)
    (export_enqueued?(user) || export_in_progress?(user)) && export_file_exists?(user)
  end

  def remove_exports
    import_export_uploads.each do |import_export_upload|
      next unless import_export_upload.export_file_exists?

      import_export_upload.remove_export_file!
      import_export_upload.save unless import_export_upload.destroyed?
    end
  end

  def remove_export_for_user(user)
    import_export_upload = import_export_upload_by_user(user)
    return unless import_export_upload&.export_file_exists?

    import_export_upload.remove_export_file!
    import_export_upload.save unless import_export_upload.destroyed?
  end

  def import_export_upload_by_user(user)
    import_export_uploads.find_by(user_id: user.id)
  end

  def export_file_exists?(user)
    import_export_upload_by_user(user)&.export_file_exists?
  end

  def export_archive_exists?(user)
    import_export_upload_by_user(user)&.export_archive_exists?
  end

  def export_file(user)
    import_export_upload_by_user(user)&.export_file
  end

  def full_path_slug
    Gitlab::Utils.slugify(full_path.to_s)
  end

  def has_ci?
    has_ci_config_file? || auto_devops_enabled?
  end

  def has_ci_config_file?
    strong_memoize(:has_ci_config_file) do
      ci_config_for('HEAD').present?
    end
  end

  def predefined_variables
    strong_memoize(:predefined_variables) do
      Gitlab::Ci::Variables::Collection.new
        .concat(predefined_ci_server_variables)
        .concat(predefined_project_variables)
        .concat(pages_variables)
        .concat(container_registry_variables)
        .concat(dependency_proxy_variables)
        .concat(auto_devops_variables)
        .concat(api_variables)
        .concat(ci_template_variables)
    end
  end

  def predefined_project_variables
    Gitlab::Ci::Variables::Collection.new
      .append(key: 'GITLAB_FEATURES', value: licensed_features.join(','))
      .append(key: 'CI_PROJECT_ID', value: id.to_s)
      .append(key: 'CI_PROJECT_NAME', value: path)
      .append(key: 'CI_PROJECT_TITLE', value: title)
      .append(key: 'CI_PROJECT_DESCRIPTION', value: description)
      .append(key: 'CI_PROJECT_PATH', value: full_path)
      .append(key: 'CI_PROJECT_PATH_SLUG', value: full_path_slug)
      .append(key: 'CI_PROJECT_NAMESPACE', value: namespace.full_path)
      .append(key: 'CI_PROJECT_NAMESPACE_ID', value: namespace.id.to_s)
      .append(key: 'CI_PROJECT_ROOT_NAMESPACE', value: namespace.root_ancestor.path)
      .append(key: 'CI_PROJECT_URL', value: web_url)
      .append(key: 'CI_PROJECT_VISIBILITY', value: Gitlab::VisibilityLevel.string_level(visibility_level))
      .append(key: 'CI_PROJECT_REPOSITORY_LANGUAGES', value: repository_languages.map(&:name).join(',').downcase)
      .append(key: 'CI_PROJECT_CLASSIFICATION_LABEL', value: external_authorization_classification_label)
      .append(key: 'CI_DEFAULT_BRANCH', value: default_branch)
      .append(key: 'CI_CONFIG_PATH', value: ci_config_path_or_default)
  end

  def predefined_ci_server_variables
    Gitlab::Ci::Variables::Collection.new
      .append(key: 'CI', value: 'true')
      .append(key: 'GITLAB_CI', value: 'true')
      .append(key: 'CI_SERVER_FQDN', value: Gitlab.config.gitlab_ci.server_fqdn)
      .append(key: 'CI_SERVER_URL', value: Gitlab.config.gitlab.url)
      .append(key: 'CI_SERVER_HOST', value: Gitlab.config.gitlab.host)
      .append(key: 'CI_SERVER_PORT', value: Gitlab.config.gitlab.port.to_s)
      .append(key: 'CI_SERVER_PROTOCOL', value: Gitlab.config.gitlab.protocol)
      .append(key: 'CI_SERVER_SHELL_SSH_HOST', value: Gitlab.config.gitlab_shell.ssh_host.to_s)
      .append(key: 'CI_SERVER_SHELL_SSH_PORT', value: Gitlab.config.gitlab_shell.ssh_port.to_s)
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
      variables.append(key: 'CI_PAGES_URL', value: pages_url) if Feature.disabled?(:fix_pages_ci_variables, self)
    end
  end

  def api_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: 'CI_API_V4_URL', value: API::Helpers::Version.new('v4').root_url)
      variables.append(key: 'CI_API_GRAPHQL_URL', value: Gitlab::Routing.url_helpers.api_graphql_url)
    end
  end

  def ci_template_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: 'CI_TEMPLATE_REGISTRY_HOST', value: 'registry.gitlab.com')
    end
  end

  def dependency_proxy_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      break variables unless Gitlab.config.dependency_proxy.enabled

      variables.append(key: 'CI_DEPENDENCY_PROXY_SERVER', value: Gitlab.host_with_port)
      variables.append(
        key: 'CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX',
        # The namespace path can include uppercase letters, which
        # Docker doesn't allow. The proxy expects it to be downcased.
        value: "#{Gitlab.host_with_port}/#{namespace.root_ancestor.path.downcase}#{DependencyProxy::URL_SUFFIX}"
      )
      variables.append(
        key: 'CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX',
        value: "#{Gitlab.host_with_port}/#{namespace.full_path.downcase}#{DependencyProxy::URL_SUFFIX}"
      )
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
    return self if project_setting.mr_default_target_self
    return self unless mr_can_target_upstream?

    forked_from_project
  end

  def mr_can_target_upstream?
    # When our current visibility is more restrictive than the upstream project,
    # (e.g., the fork is `private` but the parent is `public`), don't allow target upstream
    forked_from_project &&
      forked_from_project.merge_requests_enabled? &&
      forked_from_project.visibility_level_value <= visibility_level_value
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
    BatchLoader.for(self).batch do |projects, loader|
      fork_count_per_project = ::Projects::BatchForksCountService.new(projects).refresh_cache_and_retrieve_data

      fork_count_per_project.each do |project, count|
        loader.call(project, count)
      end
    end
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

  override :git_transfer_in_progress?
  def git_transfer_in_progress?
    GL_REPOSITORY_TYPES.any? do |type|
      reference_counter(type: type).value > 0
    end
  end

  def storage_version=(value)
    super

    @storage = nil if storage_version_changed?
  end

  def badges
    return project_badges unless group

    Badge.from_union([project_badges, GroupBadge.where(group: group.self_and_ancestors)])
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

  # Overridden in EE::Project
  def licensed_feature_available?(_feature)
    false
  end

  def licensed_features
    []
  end

  def toggle_ci_cd_settings!(settings_attribute)
    ci_cd_settings.toggle!(settings_attribute)
  end

  def gitlab_deploy_token
    strong_memoize(:gitlab_deploy_token) do
      deploy_tokens.gitlab_deploy_token || group&.gitlab_deploy_token
    end
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
        Storage::Hashed.new(self)
      else
        Storage::LegacyProject.new(self)
      end
  end

  def storage_upgradable?
    storage_version != LATEST_STORAGE_VERSION
  end

  def snippets_visible?(user = nil)
    Ability.allowed?(user, :read_snippet, self)
  end

  def max_attachment_size
    Gitlab::CurrentSettings.max_attachment_size.megabytes.to_i
  end

  def object_pool_params
    return {} unless !forked? && git_objects_poolable?

    {
      repository_storage: repository_storage,
      pool_repository: pool_repository || create_new_pool_repository
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
    return if pool_repository.blank?

    # Disconnecting the repository can be expensive, so let's skip it if
    # this repository is being deleted anyway.
    pool_repository.unlink_repository(repository, disconnect: !pending_delete?)
    update_column(:pool_repository_id, nil)
  end

  # After repository is moved from shard to shard, disconnect it from the previous object pool and connect to the new pool
  def swap_pool_repository!
    return unless repository_exists?

    old_pool_repository = pool_repository
    return if old_pool_repository.blank?
    return if pool_repository_shard_matches_repository?(old_pool_repository)

    new_pool_repository = PoolRepository.by_disk_path_and_shard_name(old_pool_repository.disk_path, repository_storage).take!
    update!(pool_repository: new_pool_repository)

    old_pool_repository.unlink_repository(repository, disconnect: !pending_delete?)
  end

  def link_pool_repository
    return unless pool_repository
    return if pool_repository.shard_name != repository.shard

    pool_repository.link_repository(repository)
  end

  def has_pool_repository?
    pool_repository.present?
  end

  def access_request_approvers_to_be_notified
    access_request_approvers = members.owners_and_maintainers

    recipients = access_request_approvers.connected_to_user.order_recent_sign_in.limit(Member::ACCESS_REQUEST_APPROVERS_TO_BE_NOTIFIED_LIMIT)

    if recipients.blank?
      recipients = group.access_request_approvers_to_be_notified
    end

    recipients
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

  def template_source?
    false
  end

  def jira_subscription_exists?
    JiraConnectSubscription.for_project(self).exists?
  end

  def limited_protected_branches(limit)
    protected_branches.limit(limit)
  end

  def group_protected_branches
    return root_namespace.protected_branches if root_namespace.is_a?(Group)

    ProtectedBranch.none
  end

  def deploy_token_create_url(opts = {})
    Gitlab::Routing.url_helpers.create_deploy_token_project_settings_repository_path(self, opts)
  end

  def deploy_token_revoke_url_for(token)
    Gitlab::Routing.url_helpers.revoke_project_deploy_token_path(self, token)
  end

  def default_branch_protected?
    branch_protection = Gitlab::Access::DefaultBranchProtection.new(self.namespace.default_branch_protection_settings)

    !branch_protection.developer_can_push?
  end

  def initial_push_to_default_branch_allowed_for_developer?
    branch_protection = Gitlab::Access::DefaultBranchProtection.new(self.namespace.default_branch_protection_settings)

    branch_protection.developer_can_push? || branch_protection.developer_can_initial_push?
  end

  def environments_for_scope(scope)
    quoted_scope = ::Gitlab::SQL::Glob.q(scope)

    environments.where("name LIKE (#{::Gitlab::SQL::Glob.to_like(quoted_scope)})") # rubocop:disable GitlabSecurity/SqlInjection
  end

  def batch_loaded_environment_by_name(name)
    # This code path has caused N+1s in the past, since environments are only indirectly
    # associated to builds and pipelines; see https://gitlab.com/gitlab-org/gitlab/-/issues/326445
    # We therefore batch-load them to prevent dormant N+1s until we found a proper solution.
    BatchLoader.for(name).batch(key: id) do |names, loader, args|
      Environment.where(name: names, project: args[:key]).find_each do |environment|
        loader.call(environment.name, environment)
      end
    end
  end

  def latest_jira_import
    jira_imports.last
  end

  def root_namespace
    if namespace.has_parent?
      namespace.root_ancestor
    else
      namespace
    end
  end

  # for projects that are part of user namespace, return project.
  def self_or_root_group_ids
    if group
      root_group = root_namespace
    else
      project = self
    end

    [project&.id, root_group&.id]
  end

  def related_group_ids
    ids = invited_group_ids

    ids += group.self_and_ancestors_ids if group

    ids
  end

  def package_already_taken?(package_name, package_version, package_type:)
    Packages::Package.with_name(package_name)
      .with_version(package_version)
      .with_package_type(package_type)
      .not_pending_destruction
      .for_projects(
        root_ancestor.all_projects
          .id_not_in(id)
          .select(:id)
      ).exists?
  end

  def default_branch_or_main
    return default_branch if default_branch

    Gitlab::DefaultBranch.value(object: self)
  end

  def ci_config_path_or_default
    ci_config_path.presence || Ci::Pipeline::DEFAULT_CONFIG_PATH
  end

  def ci_config_for(sha)
    repository.blob_data_at(sha, ci_config_path_or_default)
  end

  def enabled_group_deploy_keys
    return GroupDeployKey.none unless group

    GroupDeployKey.for_groups(group.self_and_ancestors_ids)
  end

  def feature_flags_client_token
    instance = operations_feature_flags_client || create_operations_feature_flags_client!
    instance.token
  end

  override :git_garbage_collect_worker_klass
  def git_garbage_collect_worker_klass
    Projects::GitGarbageCollectWorker
  end

  def ci_forward_deployment_enabled?
    return false unless ci_cd_settings

    ci_cd_settings.forward_deployment_enabled?
  end

  def ci_forward_deployment_rollback_allowed?
    return false unless ci_cd_settings

    ci_cd_settings.forward_deployment_rollback_allowed?
  end

  def ci_allow_fork_pipelines_to_run_in_parent_project?
    return false unless ci_cd_settings

    ci_cd_settings.allow_fork_pipelines_to_run_in_parent_project?
  end

  def ci_outbound_job_token_scope_enabled?
    return false unless ci_cd_settings

    ci_cd_settings.job_token_scope_enabled?
  end

  def ci_inbound_job_token_scope_enabled?
    return true unless ci_cd_settings

    return true if ::Gitlab::CurrentSettings.enforce_ci_inbound_job_token_scope_enabled?

    ci_cd_settings.inbound_job_token_scope_enabled?
  end

  def restrict_user_defined_variables?
    return false unless ci_cd_settings

    ci_cd_settings.restrict_user_defined_variables?
  end

  def override_pipeline_variables_allowed?(access_level)
    return false unless ci_cd_settings

    ci_cd_settings.override_pipeline_variables_allowed?(access_level)
  end

  def ci_push_repository_for_job_token_allowed?
    return false unless ci_cd_settings

    ci_cd_settings.push_repository_for_job_token_allowed?
  end

  def keep_latest_artifacts_available?
    return false unless ci_cd_settings

    ci_cd_settings.keep_latest_artifacts_available?
  end

  def keep_latest_artifact?
    return false unless ci_cd_settings

    ci_cd_settings.keep_latest_artifact?
  end

  def group_runners_enabled?
    return false unless ci_cd_settings

    ci_cd_settings.group_runners_enabled?
  end

  def topic_list
    self.topics.map(&:name)
  end

  override :after_change_head_branch_does_not_exist
  def after_change_head_branch_does_not_exist(branch)
    self.errors.add(:base, _("Could not change HEAD: branch '%{branch}' does not exist") % { branch: branch })
  end

  def visible_group_links(for_user:)
    user = for_user
    links = project_group_links_with_preload
    user.max_member_access_for_group_ids(links.map(&:group_id)) if user && links.any?

    DeclarativePolicy.user_scope do
      links.select { Ability.allowed?(user, :read_group, _1.group) }
    end
  end

  def parent_groups
    Gitlab::ObjectHierarchy.new(Group.where(id: group)).base_and_ancestors
  end

  def enforced_runner_token_expiration_interval
    group_settings = NamespaceSetting.where(namespace_id: parent_groups)
    group_interval = group_settings.where.not(project_runner_token_expiration_interval: nil).minimum(:project_runner_token_expiration_interval)&.seconds

    [
      Gitlab::CurrentSettings.project_runner_token_expiration_interval&.seconds,
      group_interval
    ].compact.min
  end

  def merge_commit_template_or_default
    merge_commit_template.presence || DEFAULT_MERGE_COMMIT_TEMPLATE
  end

  def merge_commit_template_or_default=(value)
    project_setting.merge_commit_template =
      if value.blank? || value.delete("\r") == DEFAULT_MERGE_COMMIT_TEMPLATE
        nil
      else
        value
      end
  end

  def squash_commit_template_or_default
    squash_commit_template.presence || DEFAULT_SQUASH_COMMIT_TEMPLATE
  end

  def squash_commit_template_or_default=(value)
    project_setting.squash_commit_template =
      if value.blank? || value.delete("\r") == DEFAULT_SQUASH_COMMIT_TEMPLATE
        nil
      else
        value
      end
  end

  def pending_delete_or_hidden?
    pending_delete? || hidden?
  end

  def created_and_owned_by_banned_user?
    return false unless creator

    creator.banned? && team.max_member_access(creator.id) == Gitlab::Access::OWNER
  end

  def work_items_feature_flag_enabled?
    group&.work_items_feature_flag_enabled? || Feature.enabled?(:work_items, self)
  end

  def work_items_beta_feature_flag_enabled?
    group&.work_items_beta_feature_flag_enabled? || Feature.enabled?(:work_items_beta, type: :beta)
  end

  def work_items_alpha_feature_flag_enabled?
    group&.work_items_alpha_feature_flag_enabled? || Feature.enabled?(:work_items_alpha)
  end

  def glql_integration_feature_flag_enabled?
    group&.glql_integration_feature_flag_enabled? || Feature.enabled?(:glql_integration, self)
  end

  def continue_indented_text_feature_flag_enabled?
    group&.continue_indented_text_feature_flag_enabled? || Feature.enabled?(:continue_indented_text, self, type: :wip)
  end

  def wiki_comments_feature_flag_enabled?
    group&.wiki_comments_feature_flag_enabled? || Feature.enabled?(:wiki_comments, self, type: :wip)
  end

  def enqueue_record_project_target_platforms
    return unless Gitlab.com?

    Projects::RecordTargetPlatformsWorker.perform_async(id)
  end

  def inactive?
    (statistics || build_statistics).storage_size > ::Gitlab::CurrentSettings.inactive_projects_min_size_mb.megabytes &&
      last_activity_at < ::Gitlab::CurrentSettings.inactive_projects_send_warning_email_after_months.months.ago
  end

  def refreshing_build_artifacts_size?
    build_artifacts_size_refresh&.started?
  end

  def group_group_links
    group&.shared_with_group_links_of_ancestors_and_self || GroupGroupLink.none
  end

  def security_training_available?
    licensed_feature_available?(:security_training)
  end

  def packages_policy_subject
    ::Packages::Policies::Project.new(self)
  end

  def destroy_deployment_by_id(deployment_id)
    deployments.where(id: deployment_id).fast_destroy_all
  end

  def can_create_custom_domains?
    return true if Gitlab::CurrentSettings.max_pages_custom_domains_per_project == 0

    pages_domains.count < Gitlab::CurrentSettings.max_pages_custom_domains_per_project
  end

  def pages_domain_present?(domain_url)
    pages_url == domain_url || pages_domains.any? { |domain| domain.url == domain_url }
  end

  # overridden in EE
  def can_suggest_reviewers?
    false
  end

  # overridden in EE
  def suggested_reviewers_available?
    false
  end

  def crm_enabled?
    return false unless group

    group.crm_enabled?
  end

  def crm_group
    return unless group

    group.crm_group
  end

  def supports_lock_on_merge?
    group&.supports_lock_on_merge? || ::Feature.enabled?(:enforce_locked_labels_on_merge, self, type: :ops)
  end

  def path_availability
    base, _, host = path.partition('.')

    return unless host == Gitlab.config.pages&.dig('host')
    return unless ProjectSetting.where(pages_unique_domain: base).exists?

    errors.add(:path, s_('Project|already in use'))
  end

  def repository_object_format
    project_repository&.object_format
  end

  def instance_runner_running_jobs_count
    # excluding currently started job
    ::Ci::RunningBuild.instance_type.where(project_id: self.id)
                      .limit(INSTANCE_RUNNER_RUNNING_JOBS_MAX_BUCKET + 1).count - 1
  end
  strong_memoize_attr :instance_runner_running_jobs_count

  # Overridden in EE
  def allows_multiple_merge_request_assignees?
    false
  end

  # Overridden in EE
  def allows_multiple_merge_request_reviewers?
    false
  end

  # Overridden in EE
  def on_demand_dast_available?
    false
  end

  # Overridden in EE
  def supports_saved_replies?
    false
  end

  # Overridden in EE
  def merge_trains_enabled?
    false
  end

  def lfs_file_locks_changed_epoch
    get_epoch_from(lfs_file_locks_changed_epoch_cache_key)
  end

  def refresh_lfs_file_locks_changed_epoch
    refresh_epoch_cache(lfs_file_locks_changed_epoch_cache_key)
  end

  def placeholder_reference_store
    return unless import_state

    ::Import::PlaceholderReferences::Store.new(
      import_source: import_type,
      import_uid: import_state.id
    )
  end

  def pages_url(options = nil)
    pages_url_builder(options).pages_url
  end

  def pages_hostname(options = nil)
    pages_url_builder(options).hostname
  end

  def uploads_sharding_key
    { namespace_id: namespace_id }
  end

  private

  def pages_url_builder(options = nil)
    strong_memoize_with(:pages_url_builder, options) do
      Gitlab::Pages::UrlBuilder.new(self, options)
    end
  end

  def with_redis(&block)
    Gitlab::Redis::Cache.with(&block)
  end

  def lfs_file_locks_changed_epoch_cache_key
    "project:#{id}:lfs_file_locks_changed_epoch"
  end

  def get_epoch_from(cache_key)
    with_redis { |redis| redis.get(cache_key) }&.to_i || refresh_epoch_cache(cache_key)
  end

  def refresh_epoch_cache(cache_key)
    # %s = seconds since the Unix Epoch
    # %L = milliseconds of the second
    Time.current.strftime('%s%L').to_i.tap do |epoch|
      with_redis { |redis| redis.set(cache_key, epoch, ex: EPOCH_CACHE_EXPIRATION) }
    end
  end

  # overridden in EE
  def project_group_links_with_preload
    project_group_links
  end

  def save_topics
    topic_ids_before = self.topic_ids
    update_topics
    Projects::Topic.update_non_private_projects_counter(topic_ids_before, self.topic_ids, visibility_level_previously_was, visibility_level)
  end

  def update_topics
    return if @topic_list.nil?

    @topic_list = @topic_list.split(',') if @topic_list.instance_of?(String)
    @topic_list = @topic_list.map(&:strip).uniq.reject(&:empty?)

    if @topic_list != self.topic_list
      self.topics.delete_all
      self.topics = @topic_list.map do |topic_name|
        Projects::Topic
          .for_organization(organization_id)
          .where('lower(name) = ?', topic_name.downcase)
          .order(total_projects_count: :desc)
          .first_or_create(name: topic_name, title: topic_name, slug: Gitlab::Slug::Path.new(topic_name).generate)
      end
    end

    @topic_list = nil
  end

  def find_integration(integrations, name)
    integrations.find { _1.to_param == name }
  end

  def build_from_instance(name)
    instance = find_integration(integration_instances, name)

    return unless instance

    Integration.build_from_integration(instance, project_id: id)
  end

  def build_integration(name)
    Integration.integration_name_to_model(name).new(project_id: id)
  end

  def integration_instances
    @integration_instances ||= Integration.for_instance
  end

  def closest_namespace_setting(name)
    namespace.closest_setting(name)
  end

  def app_settings_for(name)
    Gitlab::CurrentSettings.send(name) # rubocop:disable GitlabSecurity/PublicSend
  end

  def merge_requests_allowing_collaboration(source_branch = nil)
    relation = source_of_merge_requests.from_fork.opened.where(allow_collaboration: true)
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

  def check_repository_absence!
    return if skip_disk_validation

    if repository_storage.blank? || repository_with_same_path_already_exists?
      errors.add(:base, _('There is already a repository with that name on disk'))
      throw :abort # rubocop:disable Cop/BanCatchThrow
    end
  end

  def repository_with_same_path_already_exists?
    gitlab_shell.repository_exists?(repository_storage, "#{disk_path}.git")
  end

  def set_timestamps_for_create
    update_columns(last_repository_updated_at: self.created_at)
  end

  def cross_namespace_reference?(from)
    case from
    when Project
      namespace_id != from.namespace_id
    when Namespaces::ProjectNamespace
      namespace_id != from.parent_id
    when Namespace
      namespace != from
    when User
      true
    end
  end

  # Check if a reference is being done cross-project
  def cross_project_reference?(from)
    case from
    when Namespaces::ProjectNamespace
      project_namespace_id != from.id
    when Namespace
      true
    else
      from && self != from
    end
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
          merge_request.author.can?(:push_code, self) &&
            merge_request.can_be_merged_by?(user, skip_collaboration_check: true)
        end
      end
    end
  end

  def ensure_pages_metadatum
    pages_metadatum || create_pages_metadatum!
  rescue ActiveRecord::RecordNotUnique
    reset
    retry
  end

  def oids(objects, oids: [])
    objects = objects.where(oid: oids) if oids.any?

    [].tap do |out|
      objects.each_batch { |relation| out.concat(relation.pluck(:oid)) }
    end
  end

  def cache_has_external_wiki
    update_column(:has_external_wiki, integrations.external_wikis.any?) if Gitlab::Database.read_write?
  end

  def cache_has_external_issue_tracker
    update_column(:has_external_issue_tracker, integrations.external_issue_trackers.any?) if Gitlab::Database.read_write?
  end

  def online_runners_with_tags
    @online_runners_with_tags ||= active_runners.with_tags.online
  end

  def ensure_project_namespace_in_sync
    # create project_namespace when project is created
    build_project_namespace if project_namespace_creation_enabled?

    project_namespace.sync_attributes_from_project(self) if sync_project_namespace?
  end

  def project_namespace_creation_enabled?
    new_record? && !project_namespace && self.namespace
  end

  def sync_project_namespace?
    (changes.keys & %w[name path namespace_id namespace visibility_level shared_runners_enabled]).any? && project_namespace.present?
  end

  def reload_project_namespace_details
    return unless (previous_changes.keys & %w[description description_html cached_markdown_version]).any? && project_namespace.namespace_details.present?

    project_namespace.namespace_details.reset
  end

  # SyncEvents are created by PG triggers (with the function `insert_projects_sync_event`)
  def schedule_sync_event_worker
    run_after_commit do
      Projects::SyncEvent.enqueue_worker
    end
  end

  def check_project_export_limit!
    return if Gitlab::CurrentSettings.current_application_settings.max_export_size == 0

    if self.statistics.export_size > Gitlab::CurrentSettings.current_application_settings.max_export_size.megabytes
      raise ExportLimitExceeded, _('The project size exceeds the export limit.')
    end
  end

  def remove_leading_spaces_on_name
    name&.lstrip!
  end

  def set_last_activity_at
    return if last_activity_at_changed?

    if new_record? || (changed & PROJECT_ACTIVITY_ATTRIBUTES).any?
      self.last_activity_at = Time.current
    elsif last_activity_at.nil?
      self.last_activity_at = created_at
    end
  end

  def set_package_registry_access_level
    return if !project_feature || project_feature.package_registry_access_level_changed?

    self.project_feature.package_registry_access_level = packages_enabled ? enabled_package_registry_access_level_by_project_visibility : ProjectFeature::DISABLED
  end

  def enabled_package_registry_access_level_by_project_visibility
    case visibility_level
    when PUBLIC
      ProjectFeature::PUBLIC
    when INTERNAL
      ProjectFeature::ENABLED
    else
      ProjectFeature::PRIVATE
    end
  end

  def runners_token_prefix
    RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX
  end

  def pool_repository_shard_matches_repository?(pool)
    pool_repository_shard = pool.shard.name

    pool_repository_shard == repository_storage
  end

  # Catalog resource SyncEvents are created by PG triggers
  def enqueue_catalog_resource_sync_event_worker
    run_after_commit do
      ::Ci::Catalog::Resources::SyncEvent.enqueue_worker
    end
  end
end

Project.prepend_mod_with('Project')
