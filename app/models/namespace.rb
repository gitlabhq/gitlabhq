# frozen_string_literal: true

class Namespace < ApplicationRecord
  include CacheMarkdownField
  include Sortable
  include Gitlab::VisibilityLevel
  include Routable
  include AfterCommitQueue
  include Gitlab::SQL::Pattern
  include FeatureGate
  include FromUnion
  include Gitlab::Utils::StrongMemoize
  include Namespaces::Traversal::Recursive
  include Namespaces::Traversal::Linear
  include Namespaces::Traversal::Cached
  include EachBatch
  include BlocksUnsafeSerialization
  include Ci::NamespaceSettings
  include Referable
  include CrossDatabaseIgnoredTables
  include UseSqlFunctionForPrimaryKeyLookups
  include SafelyChangeColumnDefault
  include Todoable

  ignore_column :unlock_membership_to_ldap, remove_with: '16.7', remove_after: '2023-11-16'

  cross_database_ignore_tables %w[routes redirect_routes], url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424277'

  ignore_column :emails_disabled, remove_with: '17.0', remove_after: '2024-04-24'

  columns_changing_default :organization_id

  # Tells ActiveRecord not to store the full class name, in order to save some space
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/69794
  self.store_full_sti_class = false
  self.store_full_class_name = false

  # Prevent users from creating unreasonably deep level of nesting.
  # The number 20 was taken based on maximum nesting level of
  # Android repo (15) + some extra backup.
  NUMBER_OF_ANCESTORS_ALLOWED = 20

  SR_DISABLED_AND_UNOVERRIDABLE = 'disabled_and_unoverridable'
  SR_DISABLED_AND_OVERRIDABLE = 'disabled_and_overridable'
  SR_ENABLED = 'enabled'
  SHARED_RUNNERS_SETTINGS = [SR_DISABLED_AND_UNOVERRIDABLE, SR_DISABLED_AND_OVERRIDABLE, SR_ENABLED].freeze
  URL_MAX_LENGTH = 255
  STATISTICS_COLUMNS = %i[
    storage_size
    repository_size
    wiki_size
    snippets_size
    lfs_objects_size
    build_artifacts_size
    pipeline_artifacts_size
    packages_size
    uploads_size
  ].freeze

  cache_markdown_field :description, pipeline: :description

  has_many :projects, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :non_archived_projects, -> { where.not(archived: true) }, class_name: 'Project'
  has_many :project_statistics
  has_one :namespace_settings, inverse_of: :namespace, class_name: 'NamespaceSetting', autosave: true
  has_one :ci_cd_settings, inverse_of: :namespace, class_name: 'NamespaceCiCdSetting', autosave: true
  has_one :namespace_details, inverse_of: :namespace, class_name: 'Namespace::Detail', autosave: true
  has_one :namespace_statistics
  has_one :namespace_route, foreign_key: :namespace_id, autosave: false, inverse_of: :namespace, class_name: 'Route'
  has_one :catalog_verified_namespace, class_name: 'Ci::Catalog::VerifiedNamespace', inverse_of: :namespace

  has_many :namespace_members, foreign_key: :member_namespace_id, inverse_of: :member_namespace, class_name: 'Member'

  has_one :namespace_ldap_settings, inverse_of: :namespace, class_name: 'Namespaces::LdapSetting', autosave: true

  has_one :namespace_descendants, class_name: 'Namespaces::Descendants'
  accepts_nested_attributes_for :namespace_descendants, allow_destroy: true

  has_many :runner_namespaces, inverse_of: :namespace, class_name: 'Ci::RunnerNamespace'
  has_many :runners, through: :runner_namespaces, source: :runner, class_name: 'Ci::Runner'
  has_many :pending_builds, class_name: 'Ci::PendingBuild'

  # This should _not_ be `inverse_of: :namespace`, because that would also set
  # `user.namespace` when this user creates a group with themselves as `owner`.
  belongs_to :owner, class_name: 'User'
  belongs_to :organization, class_name: 'Organizations::Organization'

  belongs_to :parent, class_name: "Namespace"
  has_many :children, -> { where(type: Group.sti_name) }, class_name: "Namespace", foreign_key: :parent_id
  has_many :custom_emoji, inverse_of: :namespace
  has_one :chat_team, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_one :root_storage_statistics, class_name: 'Namespace::RootStorageStatistics'
  has_one :aggregation_schedule, class_name: 'Namespace::AggregationSchedule'
  has_one :package_setting_relation, inverse_of: :namespace, class_name: 'PackageSetting'

  has_one :admin_note, inverse_of: :namespace
  accepts_nested_attributes_for :admin_note, update_only: true

  has_one :ci_namespace_mirror, class_name: 'Ci::NamespaceMirror'
  has_many :sync_events, class_name: 'Namespaces::SyncEvent'

  has_one :cluster_enabled_grant, inverse_of: :namespace, class_name: 'Clusters::ClusterEnabledGrant'
  has_many :work_items, inverse_of: :namespace
  has_many :work_items_dates_source, inverse_of: :namespace, class_name: 'WorkItems::DatesSource'
  has_many :issues, inverse_of: :namespace

  has_many :timelog_categories, class_name: 'TimeTracking::TimelogCategory'
  has_many :achievements, class_name: 'Achievements::Achievement'
  has_many :namespace_commit_emails, class_name: 'Users::NamespaceCommitEmail'
  has_many :cycle_analytics_stages, class_name: 'Analytics::CycleAnalytics::Stage', foreign_key: :group_id, inverse_of: :namespace
  has_many :value_streams, class_name: 'Analytics::CycleAnalytics::ValueStream', foreign_key: :group_id, inverse_of: :namespace

  has_many :jira_connect_subscriptions, class_name: 'JiraConnectSubscription', foreign_key: :namespace_id, inverse_of: :namespace

  has_many :import_source_users, class_name: 'Import::SourceUser', foreign_key: :namespace_id, inverse_of: :namespace
  has_one :namespace_import_user, class_name: 'Import::NamespaceImportUser', foreign_key: :namespace_id, inverse_of: :namespace
  has_one :import_user, class_name: 'User', through: :namespace_import_user, foreign_key: :user_id

  has_many :bot_user_details, class_name: 'UserDetail', foreign_key: 'bot_namespace_id', inverse_of: :bot_namespace
  has_many :bot_users, through: :bot_user_details, source: :user

  validates :owner, presence: true, if: ->(n) { n.owner_required? }
  validates :organization, presence: true
  validates :name,
    presence: true,
    length: { maximum: 255 }
  validates :name, uniqueness: { scope: [:type, :parent_id] }, if: -> { parent_id.present? }

  validates :description, length: { maximum: 500 }

  validates :path,
    presence: true,
    length: { maximum: URL_MAX_LENGTH }

  validates :path,
    format: { with: Gitlab::Regex.oci_repository_path_regex, message: Gitlab::Regex.oci_repository_path_regex_message },
    if: :path_changed?

  validates :path, namespace_path: true, if: ->(n) { !n.project_namespace? }
  # Project path validator is used for project namespaces for now to assure
  # compatibility with project paths
  # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/341764
  validates :path, project_path: true, if: ->(n) { n.project_namespace? }

  # Introduce minimal path length of 2 characters.
  # Allow change of other attributes without forcing users to
  # rename their user or group. At the same time prevent changing
  # the path without complying with new 2 chars requirement.
  # Issue https://gitlab.com/gitlab-org/gitlab/-/issues/225214
  #
  # For ProjectNamespace we don't check minimal path length to keep
  # compatibility with existing project restrictions.
  # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/341764
  validates :path, length: { minimum: 2 }, if: :enforce_minimum_path_length?

  validates :max_artifacts_size, numericality: { only_integer: true, greater_than: 0, allow_nil: true }

  validate :validate_parent_type

  # ProjectNamespaces excluded as they are not meant to appear in the group hierarchy at the moment.
  validate :nesting_level_allowed, unless: -> { project_namespace? }
  validate :changing_shared_runners_enabled_is_allowed, unless: -> { project_namespace? }
  validate :changing_allow_descendants_override_disabled_shared_runners_is_allowed, unless: -> { project_namespace? }
  validate :parent_organization_match

  delegate :name, to: :owner, allow_nil: true, prefix: true
  delegate :avatar_url, to: :owner, allow_nil: true
  delegate :prevent_sharing_groups_outside_hierarchy, :prevent_sharing_groups_outside_hierarchy=,
    to: :namespace_settings, allow_nil: true
  delegate :show_diff_preview_in_email, :show_diff_preview_in_email?, :show_diff_preview_in_email=,
    to: :namespace_settings
  delegate :runner_registration_enabled, :runner_registration_enabled?, :runner_registration_enabled=,
    to: :namespace_settings
  delegate :emails_enabled, :emails_enabled=,
    to: :namespace_settings, allow_nil: true
  delegate :allow_runner_registration_token,
    :allow_runner_registration_token=,
    to: :namespace_settings
  delegate :maven_package_requests_forwarding,
    :pypi_package_requests_forwarding,
    :npm_package_requests_forwarding,
    to: :package_settings
  delegate :default_branch_protection_defaults, to: :namespace_settings, allow_nil: true
  delegate :math_rendering_limits_enabled,
    :lock_math_rendering_limits_enabled,
    to: :namespace_settings, allow_nil: true
  delegate :math_rendering_limits_enabled?,
    :lock_math_rendering_limits_enabled?,
    to: :namespace_settings
  delegate :add_creator, :pending_delete, :pending_delete=, :deleted_at, :deleted_at=,
    to: :namespace_details
  delegate :resource_access_token_notify_inherited,
    :resource_access_token_notify_inherited=,
    :lock_resource_access_token_notify_inherited,
    :lock_resource_access_token_notify_inherited=,
    :resource_access_token_notify_inherited?,
    :resource_access_token_notify_inherited_locked?,
    :resource_access_token_notify_inherited_locked_by_ancestor?,
    :resource_access_token_notify_inherited_locked_by_application_setting?,
    to: :namespace_settings

  before_create :sync_share_with_group_lock_with_parent
  before_update :sync_share_with_group_lock_with_parent, if: :parent_changed?
  after_update :force_share_with_group_lock_on_descendants, if: -> { saved_change_to_share_with_group_lock? && share_with_group_lock? }
  after_update :expire_first_auto_devops_config_cache, if: -> { saved_change_to_auto_devops_enabled? }

  after_save :reload_namespace_details

  after_commit :refresh_access_of_projects_invited_groups, on: :update, if: -> { previous_changes.key?('share_with_group_lock') }

  after_sync_traversal_ids :schedule_sync_event_worker # custom callback defined in Namespaces::Traversal::Linear

  after_commit :expire_child_caches, on: :update, if: -> {
    (Feature.enabled?(:cached_route_lookups, self, type: :ops) &&
      saved_change_to_name?) || saved_change_to_path? || saved_change_to_parent_id?
  }

  scope :without_deleted, -> { joins(:namespace_details).where(namespace_details: { deleted_at: nil }) }
  scope :user_namespaces, -> { where(type: Namespaces::UserNamespace.sti_name) }
  scope :group_namespaces, -> { where(type: Group.sti_name) }
  scope :project_namespaces, -> { where(type: Namespaces::ProjectNamespace.sti_name) }
  scope :without_project_namespaces, -> { where(Namespace.arel_table[:type].not_eq(Namespaces::ProjectNamespace.sti_name)) }
  scope :sort_by_type, -> { order(arel_table[:type].asc.nulls_first) }
  scope :include_route, -> { includes(:route) }
  scope :by_parent, ->(parent) { where(parent_id: parent) }
  scope :by_root_id, ->(root_id) { where('traversal_ids[1] IN (?)', root_id) }
  scope :by_not_in_root_id, ->(root_id) { where('namespaces.traversal_ids[1] NOT IN (?)', root_id) }
  scope :filter_by_path, ->(query) { where('lower(path) = :query', query: query.downcase) }
  scope :in_organization, ->(organization) { where(organization: organization) }
  scope :by_name, ->(name) { where('name LIKE ?', "#{sanitize_sql_like(name)}%") }
  scope :ordered_by_name, -> { order(:name) }
  scope :top_level, -> { by_parent(nil) }

  scope :with_statistics, -> do
    namespace_statistic_columns = STATISTICS_COLUMNS.map { |column| sum_project_statistics_column(column) }
    subquery = Arel::Table.new(:statistics)
    project_statistics = ProjectStatistics.arel_table

    statistics = project_statistics
      .project(namespace_statistic_columns)
      .where(project_statistics[:namespace_id].eq(arel_table[:id]))
      .lateral(subquery.name)

    model.select(arel_table[Arel.star], subquery[Arel.star])
         .from([arel.as(arel_table.name), statistics])
  end

  scope :with_jira_installation, ->(installation_id) do
    joins(:jira_connect_subscriptions)
    .where(jira_connect_subscriptions: { jira_connect_installation_id: installation_id })
  end

  scope :sorted_by_similarity_and_parent_id_desc, ->(search) do
    order_expression = Gitlab::Database::SimilarityScore.build_expression(
      search: search,
      rules: [
        { column: arel_table["path"], multiplier: 1 },
        { column: arel_table["name"], multiplier: 0.7 }
      ])
    reorder(order_expression.desc, Namespace.arel_table['parent_id'].desc.nulls_last, Namespace.arel_table['id'].desc)
  end

  scope :with_shared_runners_enabled, -> { where(shared_runners_enabled: true) }

  # Make sure that the name is same as strong_memoize name in root_ancestor
  # method
  attr_writer :root_ancestor, :emails_enabled_memoized

  class << self
    def sti_class_for(type_name)
      case type_name
      when Group.sti_name
        Group
      when Namespaces::ProjectNamespace.sti_name
        Namespaces::ProjectNamespace
      when Namespaces::UserNamespace.sti_name
        Namespaces::UserNamespace
      else
        Namespace
      end
    end

    def by_path(path)
      find_by('lower(path) = :value', value: path.downcase)
    end

    # Case insensitive search for namespace by path or name
    def find_by_path_or_name(path)
      find_by("lower(path) = :path OR lower(name) = :path", path: path.downcase)
    end

    def find_top_level
      top_level.take
    end

    # Searches for namespaces matching the given query.
    #
    # This method uses ILIKE on PostgreSQL.
    #
    # query - The search query as a String.
    #
    # Returns an ActiveRecord::Relation.
    def search(query, include_parents: false, use_minimum_char_limit: true, exact_matches_first: false)
      if include_parents
        route_columns = [Route.arel_table[:path], Route.arel_table[:name]]
        namespaces = without_project_namespaces
          .where(id: Route.for_routable_type(Namespace.name)
          .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/420046")
            .fuzzy_search(query, route_columns,
              use_minimum_char_limit: use_minimum_char_limit)
            .select(:source_id))

        if exact_matches_first
          namespaces = namespaces
            .joins(:route)
            .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/420046")
            .order(exact_matches_first_sql(query, route_columns))
        end

        namespaces
      else
        without_project_namespaces.fuzzy_search(query, [:path, :name], use_minimum_char_limit: use_minimum_char_limit, exact_matches_first: exact_matches_first)
      end
    end

    # This should be kept in sync with the frontend filtering in
    # https://gitlab.com/gitlab-org/gitlab/-/blob/5d34e3488faa3982d30d7207773991c1e0b6368a/app/assets/javascripts/gfm_auto_complete.js#L68 and
    # https://gitlab.com/gitlab-org/gitlab/-/blob/5d34e3488faa3982d30d7207773991c1e0b6368a/app/assets/javascripts/gfm_auto_complete.js#L1053
    def gfm_autocomplete_search(query)
      namespaces_cte = Gitlab::SQL::CTE.new(table_name, without_order)

      # This scope does not work with `ProjectNamespace` records because they don't have a corresponding `route` association.
      # We do not chain the `without_project_namespaces` scope because it results in an expensive query plan in certain cases
      unscoped
        .with(namespaces_cte.to_arel)
        .from(namespaces_cte.table)
        .joins(:route)
        .where(
          "REPLACE(routes.name, ' ', '') ILIKE :pattern OR routes.path ILIKE :pattern",
          pattern: "%#{sanitize_sql_like(query)}%"
        )
        .order(
          Arel.sql(sanitize_sql(
            [
              "CASE WHEN REPLACE(routes.name, ' ', '') ILIKE :prefix_pattern OR routes.path ILIKE :prefix_pattern THEN 1 ELSE 2 END",
              { prefix_pattern: "#{sanitize_sql_like(query)}%" }
            ]
          )),
          'routes.path'
        )
    end

    def clean_path(path, limited_to: Namespace.all)
      slug = Gitlab::Slug::Path.new(path).generate
      path = Namespaces::RandomizedSuffixPath.new(slug)
      Gitlab::Utils::Uniquify.new.string(path) { |s| limited_to.find_by_path_or_name(s) || ProjectSetting.unique_domain_exists?(s) }
    end

    def clean_name(value)
      value.scan(Gitlab::Regex.group_name_regex_chars).join(' ')
    end

    def reference_prefix
      User.reference_prefix
    end

    def reference_pattern
      User.reference_pattern
    end

    def sum_project_statistics_column(column)
      sum = ProjectStatistics.arel_table[column].sum

      coalesce = Arel::Nodes::NamedFunction.new('COALESCE', [sum, 0])
      coalesce.as(column.to_s)
    end

    def username_reserved?(username)
      without_project_namespaces.top_level.find_by_path_or_name(username).present?
    end
  end

  def to_reference_base(from = nil, full: false, absolute_path: false)
    if full || cross_namespace_reference?(from)
      absolute_path ? "/#{full_path}" : full_path
    elsif cross_project_reference?(from)
      path
    end
  end

  def to_reference(*)
    "#{self.class.reference_prefix}#{full_path}"
  end

  def package_settings
    package_setting_relation || build_package_setting_relation
  end

  def default_branch_protection
    super || Gitlab::CurrentSettings.default_branch_protection
  end

  def default_branch_protection_settings
    return Gitlab::CurrentSettings.default_branch_protection_defaults if user_namespace?

    settings = default_branch_protection_defaults

    return settings unless settings.blank?

    Gitlab::CurrentSettings.default_branch_protection_defaults
  end

  def visibility_level_field
    :visibility_level
  end

  def to_param
    full_path
  end

  def human_name
    owner_name || path
  end

  def any_project_has_container_registry_tags?
    first_project_with_container_registry_tags.present?
  end

  def first_project_with_container_registry_tags
    if Gitlab.com_except_jh? && ContainerRegistry::GitlabApiClient.supports_gitlab_api?
      ContainerRegistry::GitlabApiClient.one_project_with_container_registry_tag(full_path)
    else
      all_projects.includes(:container_repositories).find(&:has_container_registry_tags?)
    end
  end

  def send_update_instructions
    projects.each do |project|
      project.send_move_instructions("#{full_path_before_last_save}/#{project.path}")
    end
  end

  def kind
    return 'group' if group_namespace?
    return 'project' if project_namespace?

    'user' # defaults to user
  end

  def group_namespace?
    type == Group.sti_name
  end

  def project_namespace?
    type == Namespaces::ProjectNamespace.sti_name
  end

  def user_namespace?
    # That last bit ensures we're considered a user namespace as a default
    type.nil? || type == Namespaces::UserNamespace.sti_name || !(group_namespace? || project_namespace?)
  end

  def bot_user_namespace?
    return false unless user_namespace?
    return false unless owner && owner.bot?

    true
  end

  def owner_required?
    user_namespace?
  end

  def first_owner
    owner
  end

  def find_fork_of(project)
    return unless project.fork_network

    if Gitlab::SafeRequestStore.active?
      forks_in_namespace = Gitlab::SafeRequestStore.fetch("namespaces:#{id}:forked_projects") do
        Hash.new do |found_forks, project|
          found_forks[project] = project.fork_network.find_forks_in(projects).first
        end
      end

      forks_in_namespace[project]
    else
      project.fork_network.find_forks_in(projects).first
    end
  end

  # any ancestor can disable emails for all descendants
  def emails_disabled?
    !emails_enabled?
  end

  def default_branch_protected?
    Gitlab::Access::DefaultBranchProtection.new(default_branch_protection_settings).any?
  end

  def emails_enabled?
    # If no namespace_settings, we can assume it has not changed from enabled
    return true unless namespace_settings

    strong_memoize(:emails_enabled_memoized) do
      namespace_settings.emails_enabled?
    end
  end

  def lfs_enabled?
    # User namespace will always default to the global setting
    Gitlab.config.lfs.enabled
  end

  def any_project_with_shared_runners_enabled?
    projects.with_shared_runners_enabled.any?
  end

  def user_ids_for_project_authorizations
    [owner_id]
  end

  # Includes projects from this namespace and projects from all subgroups
  # that belongs to this namespace
  def all_projects
    namespace = user_namespace? ? self : self_and_descendant_ids
    Project.where(namespace: namespace)
  end

  def all_catalog_resources
    Ci::Catalog::Resource.where(project: all_projects)
  end

  def all_projects_except_soft_deleted
    all_projects.not_aimed_for_deletion
  end

  def has_parent?
    parent_id.present? || parent.present?
  end

  def subgroup?
    has_parent?
  end

  # Overridden on EE module
  def multiple_issue_boards_available?
    false
  end

  def all_project_ids_except(ids)
    all_project_ids.where.not(id: ids)
  end

  # Deprecated, use #licensed_feature_available? instead. Remove once Namespace#feature_available? isn't used anymore.
  def feature_available?(feature, _user = nil)
    licensed_feature_available?(feature)
  end

  # Overridden in EE::Namespace
  def licensed_feature_available?(_feature)
    false
  end

  def full_path_before_last_save
    if parent_id_before_last_save.nil?
      path_before_last_save
    else
      previous_parent = Group.find_by(id: parent_id_before_last_save)
      previous_parent.full_path + '/' + path_before_last_save
    end
  end

  def refresh_project_authorizations
    owner.refresh_authorized_projects
  end

  def auto_devops_enabled?
    first_auto_devops_config[:status]
  end

  def first_auto_devops_config
    return { scope: :group, status: auto_devops_enabled } unless auto_devops_enabled.nil?

    strong_memoize(:first_auto_devops_config) do
      if parent.present?
        Rails.cache.fetch(first_auto_devops_config_cache_key_for(id), expires_in: 1.day) do
          parent.first_auto_devops_config
        end
      else
        { scope: :instance, status: Gitlab::CurrentSettings.auto_devops_enabled? }
      end
    end
  end

  def aggregation_scheduled?
    aggregation_schedule.present?
  end

  def container_repositories_size_cache_key
    "namespaces:#{id}:container_repositories_size"
  end

  def container_repositories_size
    strong_memoize(:container_repositories_size) do
      next unless root?
      next unless ContainerRegistry::GitlabApiClient.supports_gitlab_api?
      next 0 if all_container_repositories.empty?

      Rails.cache.fetch(container_repositories_size_cache_key, expires_in: 7.days) do
        ContainerRegistry::GitlabApiClient.deduplicated_size(full_path)
      end
    end
  end

  def all_container_repositories
    ContainerRepository.for_project_id(all_projects)
  end

  def any_project_with_pages_deployed?
    all_projects.with_pages_deployed.any?
  end

  def closest_setting(name)
    self_and_ancestors(hierarchy_order: :asc)
      .find { |n| !n.read_attribute(name).nil? }
      .try(name)
  end

  def actual_plan
    Plan.default
  end

  def paid?
    root? && actual_plan.paid?
  end

  def linked_to_subscription?
    paid?
  end

  def actual_limits
    # We default to PlanLimits.new otherwise a lot of specs would fail
    # On production each plan should already have associated limits record
    # https://gitlab.com/gitlab-org/gitlab/issues/36037
    actual_plan.actual_limits
  end

  def actual_plan_name
    actual_plan.name
  end

  def changing_shared_runners_enabled_is_allowed
    return unless new_record? || changes.has_key?(:shared_runners_enabled)

    if shared_runners_enabled && has_parent? && parent.shared_runners_setting == SR_DISABLED_AND_UNOVERRIDABLE
      errors.add(:shared_runners_enabled, _('cannot be enabled because parent group has shared Runners disabled'))
    end
  end

  def changing_allow_descendants_override_disabled_shared_runners_is_allowed
    return unless new_record? || changes.has_key?(:allow_descendants_override_disabled_shared_runners)

    if shared_runners_enabled && allow_descendants_override_disabled_shared_runners
      errors.add(:allow_descendants_override_disabled_shared_runners, _('can not be true if shared runners are enabled'))
    end

    if allow_descendants_override_disabled_shared_runners && has_parent? && parent.shared_runners_setting == SR_DISABLED_AND_UNOVERRIDABLE
      errors.add(:allow_descendants_override_disabled_shared_runners, _('cannot be enabled because parent group does not allow it'))
    end
  end

  def shared_runners_setting
    if shared_runners_enabled
      SR_ENABLED
    elsif allow_descendants_override_disabled_shared_runners
      SR_DISABLED_AND_OVERRIDABLE
    else
      SR_DISABLED_AND_UNOVERRIDABLE
    end
  end

  def shared_runners_setting_higher_than?(other_setting)
    case other_setting
    when SR_ENABLED
      false
    when SR_DISABLED_AND_OVERRIDABLE
      shared_runners_setting == SR_ENABLED
    when SR_DISABLED_AND_UNOVERRIDABLE
      shared_runners_setting == SR_ENABLED || shared_runners_setting == SR_DISABLED_AND_OVERRIDABLE
    else
      raise ArgumentError
    end
  end

  def shared_runners
    @shared_runners ||= shared_runners_enabled ? Ci::Runner.instance_type : Ci::Runner.none
  end

  def root?
    !has_parent?
  end

  def recent?
    created_at >= 90.days.ago
  end

  def issue_repositioning_disabled?
    Feature.enabled?(:block_issue_repositioning, self, type: :ops)
  end

  def certificate_based_clusters_enabled?
    cluster_enabled_granted? || certificate_based_clusters_enabled_ff?
  end

  def enabled_git_access_protocol
    # If the instance-level setting is enabled, we defer to that
    return ::Gitlab::CurrentSettings.enabled_git_access_protocol unless ::Gitlab::CurrentSettings.enabled_git_access_protocol.blank?

    # Otherwise we use the stored setting on the group
    namespace_settings&.enabled_git_access_protocol
  end

  def all_ancestors_have_runner_registration_enabled?
    namespace_settings&.all_ancestors_have_runner_registration_enabled?
  end

  def allow_runner_registration_token?
    !!namespace_settings&.allow_runner_registration_token?
  end

  def all_projects_with_pages
    all_projects.with_pages_deployed.includes(
      :route,
      :project_setting,
      :project_feature,
      :active_pages_deployments)
  end

  def web_url(only_path: nil)
    Gitlab::UrlBuilder.build(self, only_path: only_path)
  end

  def deleted?
    !!deleted_at
  end

  def uploads_sharding_key
    { organization_id: organization_id }
  end

  def pipeline_variables_default_role
    return namespace_settings.pipeline_variables_default_role if namespace_settings.present?

    # We could have old namespaces that don't have an associated `namespace_settings` record.
    # To avoid returning `nil` we return the database-level default.
    NamespaceSetting.column_defaults['pipeline_variables_default_role']
  end

  private

  def parent_organization_match
    return unless parent
    return if parent.organization_id == organization_id

    errors.add(:organization_id, _("must match the parent organization's ID"))
  end

  def cross_namespace_reference?(from)
    return false if from == self

    comparable_namespace_id = project_namespace? ? parent_id : id

    case from
    when Project
      from.namespace_id != comparable_namespace_id
    when Namespaces::ProjectNamespace
      from.parent_id != comparable_namespace_id
    when Namespace
      is_a?(Group) ? from.id != id : parent != from
    when User
      true
    end
  end

  # Check if a reference is being done cross-project
  def cross_project_reference?(from)
    case from
    when Project
      from.project_namespace_id != id
    else
      from && self != from
    end
  end

  def cluster_enabled_granted?
    (Gitlab.com? || Gitlab.dev_or_test_env?) && root_ancestor.cluster_enabled_grant.present?
  end

  def certificate_based_clusters_enabled_ff?
    Feature.enabled?(:certificate_based_clusters, type: :ops)
  end

  def expire_child_caches
    Namespace.where(id: descendants).each_batch do |namespaces|
      namespaces.touch_all
    end

    all_projects.each_batch do |projects|
      projects.touch_all
    end
  end

  def parent_changed?
    parent_id_changed?
  end

  def saved_change_to_parent?
    saved_change_to_parent_id?
  end

  def saved_change_to_path_or_parent?
    saved_change_to_path? || saved_change_to_parent_id?
  end

  def refresh_access_of_projects_invited_groups
    Project
      .where(namespace_id: id)
      .joins(:project_group_links)
      .distinct
      .find_each do |project|
      AuthorizedProjectUpdate::ProjectRecalculateWorker.perform_async(project.id)
    end

    # Until we compare the inconsistency rates of the new specialized worker and
    # the old approach, we still run AuthorizedProjectsWorker
    # but with some delay and lower urgency as a safety net.
    enqueue_jobs_for_groups_requiring_authorizations_refresh(priority: UserProjectAccessChangedService::LOW_PRIORITY)
  end

  def enqueue_jobs_for_groups_requiring_authorizations_refresh(priority:)
    groups_requiring_authorizations_refresh = Group
                                              .joins(project_group_links: :project)
                                              .where(projects: { namespace_id: id })
                                              .distinct

    groups_requiring_authorizations_refresh.find_each do |group|
      group.refresh_members_authorized_projects(
        priority: priority
      )
    end
  end

  def nesting_level_allowed
    if ancestors.count > Group::NUMBER_OF_ANCESTORS_ALLOWED
      errors.add(:parent_id, _('has too deep level of nesting'))
    end
  end

  def validate_parent_type
    unless has_parent?
      if project_namespace?
        errors.add(:parent_id, _('must be set for a project namespace'))
      end

      return
    end

    if parent&.project_namespace?
      errors.add(:parent_id, _('project namespace cannot be the parent of another namespace'))
    end

    if user_namespace?
      errors.add(:parent_id, _('cannot be used for user namespace'))
    elsif group_namespace?
      errors.add(:parent_id, _('user namespace cannot be the parent of another namespace')) if parent.user_namespace?
    end
  end

  def reload_namespace_details
    return unless !project_namespace? && (previous_changes.keys & %w[description description_html cached_markdown_version]).any? && namespace_details.present?

    namespace_details.reset
  end

  def sync_share_with_group_lock_with_parent
    if parent&.share_with_group_lock?
      self.share_with_group_lock = true
    end
  end

  def force_share_with_group_lock_on_descendants
    # We can't use `descendants.update_all` since Rails will throw away the WITH
    # RECURSIVE statement. We also can't use WHERE EXISTS since we can't use
    # different table aliases, hence we're just using WHERE IN. Since we have a
    # maximum of 20 nested groups this should be fine.
    Namespace.where(id: descendants.select(:id))
      .update_all(share_with_group_lock: true)
  end

  def expire_first_auto_devops_config_cache
    descendants_to_expire = self_and_descendants.as_ids
    return if descendants_to_expire.load.empty?

    keys = descendants_to_expire.map { |group| first_auto_devops_config_cache_key_for(group.id) }
    Rails.cache.delete_multi(keys)
  end

  def enforce_minimum_path_length?
    path_changed? && !project_namespace?
  end

  # SyncEvents are created by PG triggers (with the function `insert_namespaces_sync_event`)
  def schedule_sync_event_worker
    run_after_commit do
      Namespaces::SyncEvent.enqueue_worker
    end
  end

  def first_auto_devops_config_cache_key_for(group_id)
    # Use SHA2 of `traversal_ids` to account for moving a namespace within the same root ancestor hierarchy.
    "namespaces:{#{traversal_ids.first}}:first_auto_devops_config:#{group_id}:#{Digest::SHA2.hexdigest(traversal_ids.join(' '))}"
  end
end

Namespace.prepend_mod_with('Namespace')
