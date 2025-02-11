# frozen_string_literal: true

require 'carrierwave/orm/activerecord'

class Group < Namespace
  include Gitlab::ConfigHelper
  include AfterCommitQueue
  include AccessRequestable
  include Avatarable
  include SelectForProjectAuthorization
  include LoadedInGroupList
  include GroupDescendant
  include TokenAuthenticatable
  include WithUploads
  include Gitlab::Utils::StrongMemoize
  include GroupAPICompatibility
  include EachBatch
  include BulkMemberAccessLoad
  include BulkUsersByEmailLoad
  include ChronicDurationAttribute
  include RunnerTokenExpirationInterval
  include Importable
  include IdInOrdered
  include Members::Enumerable

  extend ::Gitlab::Utils::Override

  self.allow_legacy_sti_class = true

  README_PROJECT_PATH = 'gitlab-profile'

  def self.sti_name
    'Group'
  end

  def self.supported_keyset_orderings
    { name: [:asc] }
  end

  has_many :all_group_members, -> { non_request }, dependent: :destroy, as: :source, class_name: 'GroupMember' # rubocop:disable Cop/ActiveRecordDependent
  has_many :all_owner_members, -> { non_request.all_owners }, as: :source, class_name: 'GroupMember'
  has_many :group_members, -> { non_request.non_minimal_access }, dependent: :destroy, as: :source # rubocop:disable Cop/ActiveRecordDependent
  has_many :non_invite_group_members, -> { non_request.non_minimal_access.non_invite }, class_name: 'GroupMember', as: :source
  has_many :non_invite_owner_members, -> { non_request.non_invite.all_owners }, class_name: 'GroupMember', as: :source
  has_many :request_group_members, -> do
    request.non_minimal_access
  end, inverse_of: :group, class_name: 'GroupMember', as: :source

  has_many :namespace_members, -> { non_request.non_minimal_access.unscope(where: %i[source_id source_type]) },
    foreign_key: :member_namespace_id, inverse_of: :group, class_name: 'GroupMember'
  alias_method :members, :group_members

  has_many :users, through: :group_members
  has_many :owners, through: :all_owner_members, source: :user

  has_many :requesters, -> { where.not(requested_at: nil) }, dependent: :destroy, as: :source, class_name: 'GroupMember' # rubocop:disable Cop/ActiveRecordDependent
  has_many :namespace_requesters, -> { where.not(requested_at: nil).unscope(where: %i[source_id source_type]) },
    foreign_key: :member_namespace_id, inverse_of: :group, class_name: 'GroupMember'

  has_many :members_and_requesters, as: :source, class_name: 'GroupMember'
  has_many :namespace_members_and_requesters, -> { unscope(where: %i[source_id source_type]) },
    foreign_key: :member_namespace_id, inverse_of: :group, class_name: 'GroupMember'

  has_many :milestones
  has_many :integrations

  with_options class_name: 'GroupGroupLink' do
    has_many :shared_group_links, foreign_key: :shared_with_group_id

    with_options foreign_key: :shared_group_id do
      has_many :shared_with_group_links
      has_many :shared_with_group_links_of_ancestors, ->(group) do
        unscope(where: :shared_group_id).where(shared_group: group.ancestors)
      end
      has_many :shared_with_group_links_of_ancestors_and_self, ->(group) do
        unscope(where: :shared_group_id).where(shared_group: group.self_and_ancestors)
      end
    end
  end

  has_many :shared_groups, through: :shared_group_links, source: :shared_group
  with_options source: :shared_with_group do
    has_many :shared_with_groups, through: :shared_with_group_links
    has_many :shared_with_groups_of_ancestors, through: :shared_with_group_links_of_ancestors
    has_many :shared_with_groups_of_ancestors_and_self, through: :shared_with_group_links_of_ancestors_and_self
  end

  has_many :project_group_links, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :shared_projects, through: :project_group_links, source: :project

  # Overridden on another method
  # Left here just to be dependent: :destroy
  has_many :notification_settings, dependent: :destroy, as: :source # rubocop:disable Cop/ActiveRecordDependent

  has_many :labels, class_name: 'GroupLabel'
  has_many :variables, class_name: 'Ci::GroupVariable'
  has_many :daily_build_group_report_results, class_name: 'Ci::DailyBuildGroupReportResult'
  has_many :custom_attributes, class_name: 'GroupCustomAttribute'

  has_many :boards
  has_many :badges, class_name: 'GroupBadge'

  # AR defaults to nullify when trying to delete via has_many associations unless we set dependent: :delete_all
  has_many :crm_organizations, class_name: 'CustomerRelations::Organization', inverse_of: :group, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
  has_many :contacts, class_name: 'CustomerRelations::Contact', inverse_of: :group, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
  has_one :crm_settings, class_name: 'Group::CrmSettings', inverse_of: :group
  # Groups for which this is the source of CRM contacts/organizations
  has_many :crm_targets, class_name: 'Group::CrmSettings', inverse_of: :source_group, foreign_key: 'source_group_id'

  has_many :cluster_groups, class_name: 'Clusters::Group'
  has_many :clusters, through: :cluster_groups, class_name: 'Clusters::Cluster'

  has_many :container_repositories, through: :projects

  has_many :todos

  has_many :import_export_uploads, dependent: :destroy, inverse_of: :group # rubocop:disable Cop/ActiveRecordDependent -- Previously was has_one association, dependent: :destroy to be removed in a separate issue and cascade FK will be added

  has_many :import_failures, inverse_of: :group

  has_one :import_state, class_name: 'GroupImportState', inverse_of: :group

  has_many :bulk_import_exports, class_name: 'BulkImports::Export', inverse_of: :group
  has_many :bulk_import_entities, class_name: 'BulkImports::Entity', foreign_key: :namespace_id, inverse_of: :group

  has_many :group_deploy_keys_groups, inverse_of: :group
  has_many :group_deploy_keys, through: :group_deploy_keys_groups
  has_many :group_deploy_tokens
  has_many :deploy_tokens, through: :group_deploy_tokens
  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  has_one :dependency_proxy_setting, class_name: 'DependencyProxy::GroupSetting'
  has_one :dependency_proxy_image_ttl_policy, class_name: 'DependencyProxy::ImageTtlGroupPolicy'
  has_many :dependency_proxy_blobs, class_name: 'DependencyProxy::Blob'
  has_many :dependency_proxy_manifests, class_name: 'DependencyProxy::Manifest'

  has_one :harbor_integration, class_name: 'Integrations::Harbor'

  # debian_distributions and associated component_files must be destroyed by ruby code in order to properly remove carrierwave uploads
  has_many :debian_distributions, class_name: 'Packages::Debian::GroupDistribution', dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  has_many :group_callouts, class_name: 'Users::GroupCallout', foreign_key: :group_id

  has_many :protected_branches, inverse_of: :group, foreign_key: :namespace_id

  has_one :group_feature, inverse_of: :group, class_name: 'Groups::FeatureSetting'

  delegate :prevent_sharing_groups_outside_hierarchy, :new_user_signups_cap, :setup_for_company, :jobs_to_be_done, :seat_control, to: :namespace_settings
  delegate :runner_token_expiration_interval, :runner_token_expiration_interval=, :runner_token_expiration_interval_human_readable, :runner_token_expiration_interval_human_readable=, to: :namespace_settings, allow_nil: true
  delegate :subgroup_runner_token_expiration_interval, :subgroup_runner_token_expiration_interval=, :subgroup_runner_token_expiration_interval_human_readable, :subgroup_runner_token_expiration_interval_human_readable=, to: :namespace_settings, allow_nil: true
  delegate :project_runner_token_expiration_interval, :project_runner_token_expiration_interval=, :project_runner_token_expiration_interval_human_readable, :project_runner_token_expiration_interval_human_readable=, to: :namespace_settings, allow_nil: true
  delegate :force_pages_access_control, :force_pages_access_control=, to: :namespace_settings, allow_nil: true

  accepts_nested_attributes_for :variables, allow_destroy: true
  accepts_nested_attributes_for :group_feature, update_only: true

  validate :visibility_level_allowed_by_projects
  validate :visibility_level_allowed_by_sub_groups
  validate :visibility_level_allowed_by_organization, if: :should_validate_visibility_level?
  validate :visibility_level_allowed_by_parent
  validate :two_factor_authentication_allowed
  validates :variables, nested_attributes_duplicates: { scope: :environment_scope }

  validates :two_factor_grace_period, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validates :name,
    html_safety: true,
    format: {
      with: Gitlab::Regex.group_name_regex,
      message: Gitlab::Regex.group_name_regex_message
    },
    if: :name_changed?

  validates :group_feature, presence: true

  validate :top_level_group_name_not_assigned_to_pages_unique_domain, if: :path_changed?

  add_authentication_token_field :runners_token,
    encrypted: :required,
    format_with_prefix: :runners_token_prefix,
    require_prefix_for_validation: true

  after_create :post_create_hook
  after_create -> { create_or_load_association(:group_feature) }
  after_update :path_changed_hook, if: :saved_change_to_path?
  after_destroy :post_destroy_hook
  after_commit :update_two_factor_requirement

  scope :with_users, -> { includes(:users) }

  scope :with_non_archived_projects, -> { includes(:non_archived_projects) }

  scope :with_non_invite_group_members, -> { includes(:non_invite_group_members) }
  scope :with_request_group_members, -> { includes(:request_group_members) }

  scope :by_id, ->(groups) { where(id: groups) }

  scope :by_ids_or_paths, ->(ids, paths) do
    return by_id(ids) unless paths.present?

    ids_by_full_path = Route
      .for_routable_type(Namespace.name)
      .where('LOWER(routes.path) IN (?)', paths.map(&:downcase))
      .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/420046")
      .select(:namespace_id)

    Group.from_union([by_id(ids), by_id(ids_by_full_path), where('LOWER(path) IN (?)', paths.map(&:downcase))])
  end

  scope :excluding_groups, ->(groups) { where.not(id: groups) }

  scope :by_visibility_level, ->(visibility) do
    where(visibility_level: Gitlab::VisibilityLevel.level_value(visibility)) if visibility.present?
  end

  scope :for_authorized_group_members, ->(user_ids) do
    joins(:group_members)
      .where(members: { user_id: user_ids })
      .where("access_level >= ?", Gitlab::Access::GUEST)
  end

  scope :for_authorized_project_members, ->(user_ids) do
    joins(projects: :project_authorizations)
      .where(project_authorizations: { user_id: user_ids })
  end

  scope :with_project_creation_levels, ->(project_creation_levels) do
    where(project_creation_level: project_creation_levels)
  end

  scope :excluding_restricted_visibility_levels_for_user, ->(user) do
    return all if user.can_admin_all_resources?

    levels = Array.wrap(Gitlab::CurrentSettings.restricted_visibility_levels).sort

    case levels
    when [Gitlab::VisibilityLevel::PRIVATE, Gitlab::VisibilityLevel::PUBLIC],
         [Gitlab::VisibilityLevel::PRIVATE]
      where.not(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    when [Gitlab::VisibilityLevel::PRIVATE, Gitlab::VisibilityLevel::INTERNAL]
      where.not(visibility_level: [Gitlab::VisibilityLevel::PRIVATE, Gitlab::VisibilityLevel::INTERNAL])
    when Gitlab::VisibilityLevel.values
      none
    else
      all
    end
  end

  scope :project_creation_allowed, ->(user) do
    project_creation_levels_for_user = project_creation_levels_for_user(user)

    with_project_creation_levels(project_creation_levels_for_user)
      .excluding_restricted_visibility_levels_for_user(user)
  end

  scope :shared_into_ancestors, ->(group) do
    joins(:shared_group_links)
      .where(group_group_links: { shared_group_id: group.self_and_ancestors })
  end

  # Returns all groups that are shared with the given group (see :shared_with_group)
  # and all descendents of the given group
  # returns none if the given group is nil
  scope :descendants_with_shared_with_groups, ->(group) do
    return none if group.nil?

    descendants_query = group.descendants.select(:id)
    # since we're only interested in ids, we query GroupGroupLink directly instead of using :shared_with_group
    # to avoid an extra JOIN in the resulting query
    shared_groups_query = GroupGroupLink
      .where(shared_group_id: group.id)
      .select('shared_with_group_id AS id')

    combined_query = Group
      .from_union(descendants_query, shared_groups_query, alias_as: :combined)
      .unscope(where: :type)
      .select(:id)

    id_in(combined_query)
  end

  # WARNING: This method should never be used on its own
  # please do make sure the number of rows you are filtering is small
  # enough for this query
  #
  # It's a replacement for `public_or_visible_to_user` that correctly
  # supports subgroup permissions
  scope :accessible_to_user, ->(user) do
    if user
      Preloaders::GroupPolicyPreloader.new(self, user).execute

      select { |group| user.can?(:read_group, group) }
    else
      public_to_user
    end
  end

  scope :order_path_asc, -> { reorder(self.arel_table['path'].asc) }
  scope :order_path_desc, -> { reorder(self.arel_table['path'].desc) }
  scope :in_organization, ->(organization) { where(organization: organization) }
  scope :by_min_access_level, ->(user, access_level) { joins(:group_members).where(members: { user: user }).where('members.access_level >= ?', access_level) }

  class << self
    def sort_by_attribute(method)
      case method.to_s
      when 'storage_size_desc'
        # storage_size is a virtual column so we need to
        # pass a string to avoid AR adding the table name
        reorder('storage_size DESC, namespaces.id DESC')
      when 'path_asc'
        order_path_asc
      when 'path_desc'
        order_path_desc
      else
        order_by(method)
      end
    end

    # WARNING: This method should never be used on its own
    # please do make sure the number of rows you are filtering is small
    # enough for this query
    def public_or_visible_to_user(user)
      return public_to_user unless user

      public_for_user = public_to_user_arel(user)
      visible_for_user = visible_to_user_arel(user)
      public_or_visible = public_for_user.or(visible_for_user)

      where(public_or_visible)
    end

    def select_for_project_authorization
      if current_scope.joins_values.include?(:shared_projects)
        joins('INNER JOIN namespaces project_namespace ON project_namespace.id = projects.namespace_id')
          .where(project_namespace: { share_with_group_lock: false })
          .select("projects.id AS project_id", "LEAST(project_group_links.group_access, members.access_level) AS access_level")
      else
        super
      end
    end

    def without_integration(integration)
      integrations = Integration
        .select('1')
        .where("#{Integration.table_name}.group_id = namespaces.id")
        .where(type: integration.type)

      where('NOT EXISTS (?)', integrations)
    end

    def groups_user_can(groups, user, action, same_root: false)
      DeclarativePolicy.user_scope do
        groups.select { |group| Ability.allowed?(user, action, group) }
      end
    end

    # This method can be used only if all groups have the same top-level
    # group
    def preset_root_ancestor_for(groups)
      return groups if groups.size < 2

      root = groups.first.root_ancestor
      groups.drop(1).each { |group| group.root_ancestor = root }
    end

    # Returns the ids of the passed group models where the `emails_enabled`
    # column is set to false anywhere in the ancestor hierarchy.
    def ids_with_disabled_email(groups)
      inner_groups = Group.where('id = namespaces_with_emails_disabled.id')
      inner_query = inner_groups
        .self_and_ancestors
        .joins(:namespace_settings)
        .where(namespace_settings: { emails_enabled: false })
        .select('1')
        .limit(1)

      group_ids = Namespace
        .from('(SELECT * FROM namespaces) as namespaces_with_emails_disabled')
        .where(namespaces_with_emails_disabled: { id: groups })
        .where('EXISTS (?)', inner_query)
        .pluck(:id)

      Set.new(group_ids)
    end

    def get_ids_by_ids_or_paths(ids, paths)
      by_ids_or_paths(ids, paths).pluck(:id)
    end

    def descendant_groups_counts
      left_joins(:children).group(:id).count(:children_namespaces)
    end

    def projects_counts
      left_joins(:non_archived_projects).group(:id).count(:projects)
    end

    def group_members_counts
      left_joins(:group_members).group(:id).count(:members)
    end

    def with_api_scopes
      preload(:namespace_settings, :group_feature, :parent)
    end

    # Handle project creation permissions based on application setting and group setting. The `default_project_creation`
    # application setting is the default value and can be overridden by the `project_creation_level` group setting.
    # `nil` value of namespaces.project_creation_level` means that allowed creation level has not been explicitly set by
    # the group owner and is a placeholder value for inheriting the value from the ApplicationSetting.
    def project_creation_levels_for_user(user)
      project_creation_allowed_on_levels = [
        ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS,
        ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS,
        ::Gitlab::Access::OWNER_PROJECT_ACCESS,
        nil
      ]

      if user.can_admin_all_resources?
        project_creation_allowed_on_levels << ::Gitlab::Access::ADMINISTRATOR_PROJECT_ACCESS
      end

      default_project_creation = ::Gitlab::CurrentSettings.default_project_creation
      prevent_project_creation_by_default = prevent_project_creation?(user, default_project_creation)

      # Remove nil (i.e. inherited `default_project_creation`) when the application setting is:
      # 1. NO_ONE_PROJECT_ACCESS
      # 2. ADMINISTRATOR_PROJECT_ACCESS and the user is not an admin
      #
      # To prevent showing groups in the namespaces dropdown on the project creation page that have no explicit group
      # setting for `project_creation_level`.
      project_creation_allowed_on_levels.delete(nil) if prevent_project_creation_by_default

      project_creation_allowed_on_levels
    end

    def prevent_project_creation?(user, project_creation_setting)
      return true if project_creation_setting == ::Gitlab::Access::NO_ONE_PROJECT_ACCESS
      return false if user.can_admin_all_resources?

      project_creation_setting == ::Gitlab::Access::ADMINISTRATOR_PROJECT_ACCESS
    end

    private

    def public_to_user_arel(user)
      self.arel_table[:visibility_level]
        .in(Gitlab::VisibilityLevel.levels_for_user(user))
    end

    def visible_to_user_arel(user)
      groups_table = self.arel_table
      authorized_groups = user.authorized_groups.arel.as('authorized')

      groups_table.project(1)
        .from(authorized_groups)
        .where(authorized_groups[:id].eq(groups_table[:id]))
        .exists
    end
  end

  # Overrides notification_settings has_many association
  # This allows to apply notification settings from parent groups
  # to child groups and projects.
  def notification_settings(hierarchy_order: nil)
    source_type = self.class.base_class.name
    settings = NotificationSetting.where(source_type: source_type, source_id: self_and_ancestors_ids)

    return settings unless hierarchy_order && self_and_ancestors_ids.length > 1

    settings
      .joins("LEFT JOIN (#{self_and_ancestors(hierarchy_order: hierarchy_order).to_sql}) AS ordered_groups ON notification_settings.source_id = ordered_groups.id")
      .select('notification_settings.*, ordered_groups.depth AS depth')
      .order("ordered_groups.depth #{hierarchy_order}")
  end

  def notification_settings_for(user, hierarchy_order: nil)
    notification_settings(hierarchy_order: hierarchy_order).where(user: user)
  end

  def packages_feature_enabled?
    ::Gitlab.config.packages.enabled
  end

  def dependency_proxy_feature_available?
    ::Gitlab.config.dependency_proxy.enabled
  end

  def notification_email_for(user)
    # Finds the closest notification_setting with a `notification_email`
    notification_settings = notification_settings_for(user, hierarchy_order: :asc)
    notification_settings.find { |n| n.notification_email.present? }&.notification_email
  end

  def dependency_proxy_image_prefix
    # The namespace path can include uppercase letters, which
    # Docker doesn't allow. The proxy expects it to be downcased.
    url = "#{Gitlab::Routing.url_helpers.group_url(self).downcase}#{DependencyProxy::URL_SUFFIX}"

    # Docker images do not include the protocol
    url.partition('//').last
  end

  def human_name
    full_name
  end

  def to_human_reference(from = nil)
    return unless cross_namespace_reference?(from)

    human_name
  end

  def visibility_level_allowed_by_organization?(level = self.visibility_level)
    return true unless organization

    level <= organization.visibility_level
  end

  def visibility_level_allowed_by_parent?(level = self.visibility_level)
    return true unless parent_id && parent_id.nonzero?

    level <= parent.visibility_level
  end

  def visibility_level_allowed_by_projects?(level = self.visibility_level)
    !projects.not_aimed_for_deletion.where('visibility_level > ?', level).exists?
  end

  def visibility_level_allowed_by_sub_groups?(level = self.visibility_level)
    !children.where('visibility_level > ?', level).exists?
  end

  def visibility_level_allowed?(level = self.visibility_level)
    visibility_level_allowed_by_organization?(level) &&
      visibility_level_allowed_by_parent?(level) &&
      visibility_level_allowed_by_projects?(level) &&
      visibility_level_allowed_by_sub_groups?(level)
  end

  def lfs_enabled?
    return false unless Gitlab.config.lfs.enabled
    return Gitlab.config.lfs.enabled if self[:lfs_enabled].nil?

    self[:lfs_enabled]
  end

  def owned_by?(user)
    return false unless user

    non_invite_owner_members.exists?(user: user)
  end

  def add_members(users, access_level, current_user: nil, expires_at: nil)
    Members::Groups::CreatorService.add_members( # rubocop:disable CodeReuse/ServiceClass
      self,
      users,
      access_level,
      current_user: current_user,
      expires_at: expires_at
    )
  end

  def add_member(user, access_level, ...)
    Members::Groups::CreatorService.add_member(self, user, access_level, ...) # rubocop:disable CodeReuse/ServiceClass
  end

  def add_guest(user, current_user = nil)
    add_member(user, :guest, current_user: current_user)
  end

  def add_planner(user, current_user = nil)
    add_member(user, :planner, current_user: current_user)
  end

  def add_reporter(user, current_user = nil)
    add_member(user, :reporter, current_user: current_user)
  end

  def add_developer(user, current_user = nil)
    add_member(user, :developer, current_user: current_user)
  end

  def add_maintainer(user, current_user = nil)
    add_member(user, :maintainer, current_user: current_user)
  end

  def add_owner(user, current_user = nil)
    add_member(user, :owner, current_user: current_user)
  end

  def member?(user, min_access_level = Gitlab::Access::GUEST)
    return false unless user

    max_member_access_for_user(user) >= min_access_level
  end

  def has_owner?(user)
    return false unless user

    members_with_parents.all_owners.exists?(user_id: user)
  end

  def blocked_owners
    members.blocked.where(access_level: Gitlab::Access::OWNER)
  end

  def has_maintainer?(user)
    return false unless user

    members_with_parents.maintainers.exists?(user_id: user)
  end

  def has_container_repository_including_subgroups?
    ::ContainerRepository.for_group_and_its_subgroups(self).exists?
  end

  # Check if user is a last owner of the group.
  # Excludes non-direct owners for top-level group
  # Excludes project_bots
  def last_owner?(user)
    return false unless user

    all_owners = member_owners_excluding_project_bots

    all_owners.size == 1 && all_owners.first.user_id == user.id
  end

  # Excludes non-direct owners for top-level group
  # Excludes project_bots
  def member_owners_excluding_project_bots
    members_from_hiearchy = if root?
                              members.non_minimal_access.without_invites_and_requests
                            else
                              members_with_parents(only_active_users: false)
                            end

    owners = []

    members_from_hiearchy.all_owners.non_invite.each_batch do |relation|
      owners += relation.preload(:user, :source).load.reject do |member|
        member.user.nil? || member.user.project_bot?
      end
    end

    owners
  end

  def ldap_synced?
    false
  end

  def post_create_hook
    Gitlab::AppLogger.info("Group \"#{name}\" was created")

    system_hook_service.execute_hooks_for(self, :create)
  end

  def post_destroy_hook
    Gitlab::AppLogger.info("Group \"#{name}\" was removed")

    system_hook_service.execute_hooks_for(self, :destroy)
  end

  # rubocop: disable CodeReuse/ServiceClass
  def system_hook_service
    SystemHooksService.new
  end
  # rubocop: enable CodeReuse/ServiceClass

  # rubocop: disable CodeReuse/ServiceClass
  def refresh_members_authorized_projects(
    priority: UserProjectAccessChangedService::HIGH_PRIORITY,
    direct_members_only: false
  )

    user_ids = if direct_members_only
                 users_ids_of_direct_members
               else
                 user_ids_for_project_authorizations
               end

    UserProjectAccessChangedService
      .new(user_ids)
      .execute(priority: priority)
  end
  # rubocop: enable CodeReuse/ServiceClass

  def users_ids_of_direct_members
    direct_members.pluck_user_ids
  end

  def user_ids_for_project_authorizations
    members_with_parents.pluck(Arel.sql('DISTINCT members.user_id'))
  end

  def self_and_hierarchy_intersecting_with_user_groups(user)
    user_groups = GroupsFinder.new(user).execute.unscope(:order)
    self_and_hierarchy.unscope(:order).where(id: user_groups)
  end

  def self_and_ancestors_ids
    strong_memoize(:self_and_ancestors_ids) do
      self_and_ancestors.pluck(:id)
    end
  end

  def self_and_descendants_ids
    strong_memoize(:self_and_descendants_ids) do
      self_and_descendants.pluck(:id)
    end
  end

  def self_and_ancestors_asc
    self_and_ancestors(hierarchy_order: :asc)
  end
  strong_memoize_attr :self_and_ancestors_asc

  # Only for direct and not requested members with higher access level than MIMIMAL_ACCESS
  # It returns true for non-active users
  def has_user?(user)
    return false unless user

    group_members.non_invite.exists?(user: user)
  end

  def direct_members
    GroupMember.active_without_invites_and_requests
               .non_minimal_access
               .where(source_id: id)
  end

  def authorizable_members_with_parents
    Members::MembersWithParents.new(self).all_members.authorizable
  end

  def members_with_parents(only_active_users: true)
    Members::MembersWithParents
      .new(self)
      .members(active_users: only_active_users)
  end

  def members_from_self_and_ancestors_with_effective_access_level
    members_with_parents.select([:user_id, 'MAX(access_level) AS access_level'])
                        .group(:user_id)
  end

  def members_with_descendants
    GroupMember
      .active_without_invites_and_requests
      .where(source_id: self_and_descendants.reorder(nil).select(:id))
  end

  # Returns all members that are part of the group, it's subgroups, and ancestor groups
  def hierarchy_members
    GroupMember
      .active_without_invites_and_requests
      .where(source_id: self_and_hierarchy.reorder(nil).select(:id))
  end

  def hierarchy_members_with_inactive
    GroupMember
      .non_request
      .non_invite
      .where(source_id: self_and_hierarchy.reorder(nil).select(:id))
  end

  def descendant_project_members_with_inactive
    ProjectMember
      .with_source_id(all_projects)
      .non_request
      .non_invite
  end

  def users_with_descendants
    User
      .where(id: members_with_descendants.select(:user_id))
      .reorder(nil)
  end

  def users_count
    members.count
  end

  # Return the highest access level for a user
  #
  # A special case is handled here when the user is a GitLab admin
  # which implies it has "OWNER" access everywhere, but should not
  # officially appear as a member of a group unless specifically added to it
  #
  # @param user [User]
  # @param only_concrete_membership [Bool] whether require admin concrete membership status
  def max_member_access_for_user(user, only_concrete_membership: false)
    return GroupMember::NO_ACCESS unless user

    unless only_concrete_membership
      return GroupMember::OWNER if user.can_admin_all_resources?
      return GroupMember::OWNER if user.can_admin_organization?(organization)
    end

    max_member_access(user)
  end

  def mattermost_team_params
    max_length = 59

    {
      name: path[0..max_length],
      display_name: name[0..max_length],
      type: public? ? 'O' : 'I' # Open vs Invite-only
    }
  end

  def member(user)
    if group_members.loaded?
      group_members.find { |gm| gm.user_id == user.id }
    else
      group_members.find_by(user_id: user)
    end
  end

  def highest_group_member(user)
    GroupMember
      .where(source_id: self_and_ancestors_ids, user_id: user.id)
      .non_request
      .order(:access_level)
      .last
  end

  def bots
    users.project_bot
  end

  def related_group_ids
    [id,
      *ancestors.pluck(:id),
      *shared_with_group_links.pluck(:shared_with_group_id)]
  end

  def hashed_storage?(_feature)
    false
  end

  def refresh_project_authorizations
    refresh_members_authorized_projects
  end

  # each existing group needs to have a `runners_token`.
  # we do this on read since migrating all existing groups is not a feasible
  # solution.
  def runners_token
    return unless allow_runner_registration_token?

    ensure_runners_token!
  end

  def project_creation_level
    super || ::Gitlab::CurrentSettings.default_project_creation
  end

  def subgroup_creation_level
    super || ::Gitlab::Access::OWNER_SUBGROUP_ACCESS
  end

  def access_request_approvers_to_be_notified
    members.owners.connected_to_user.order_recent_sign_in.limit(Member::ACCESS_REQUEST_APPROVERS_TO_BE_NOTIFIED_LIMIT)
  end

  def membership_locked?
    false # to support project and group calling this as 'source'
  end

  def supports_events?
    false
  end

  def import_export_upload_by_user(user)
    import_export_uploads.find_by(user_id: user.id)
  end

  def export_file_exists?(user)
    import_export_upload_by_user(user)&.export_file_exists?
  end

  def export_file(user)
    import_export_upload_by_user(user)&.export_file
  end

  def export_archive_exists?(user)
    import_export_upload_by_user(user)&.export_archive_exists?
  end

  def adjourned_deletion?
    false
  end

  def execute_hooks(data, hooks_scope)
    # NOOP
    # TODO: group hooks https://gitlab.com/gitlab-org/gitlab/-/issues/216904
  end

  def execute_integrations(data, hooks_scope)
    integrations.public_send(hooks_scope).each do |integration| # rubocop:disable GitlabSecurity/PublicSend
      integration.async_execute(data)
    end
  end

  def preload_shared_group_links
    ActiveRecord::Associations::Preloader.new(
      records: [self],
      associations: { shared_with_group_links: [shared_with_group: :route] }
    ).call
  end

  def first_owner
    first_owner_member = all_group_members.all_owners.order(:user_id).first

    first_owner_member&.user || parent&.first_owner || owner
  end

  def default_branch_name
    namespace_settings&.default_branch_name
  end

  def access_level_roles
    GroupMember.access_level_roles
  end

  def access_level_values
    access_level_roles.values
  end

  def parent_allows_two_factor_authentication?
    return true unless has_parent?

    ancestor_settings = ancestors.find_top_level.namespace_settings
    ancestor_settings.allow_mfa_for_subgroups
  end

  def has_project_with_service_desk_enabled?
    ::ServiceDesk.supported? && all_projects.service_desk_enabled.exists?
  end
  strong_memoize_attr :has_project_with_service_desk_enabled?

  # rubocop: disable CodeReuse/ServiceClass
  def open_issues_count(current_user = nil)
    Groups::OpenIssuesCountService.new(self, current_user).count
  end
  # rubocop: enable CodeReuse/ServiceClass

  # rubocop: disable CodeReuse/ServiceClass
  def open_merge_requests_count(current_user = nil)
    Groups::MergeRequestsCountService.new(self, current_user).count
  end
  # rubocop: enable CodeReuse/ServiceClass

  def timelogs
    Timelog.in_group(self)
  end

  def dependency_proxy_image_ttl_policy
    super || build_dependency_proxy_image_ttl_policy
  end

  def dependency_proxy_setting
    super || build_dependency_proxy_setting
  end

  def group_feature
    super || build_group_feature
  end

  def crm_enabled?
    crm_settings.nil? || crm_settings.enabled?
  end

  def shared_with_group_links_visible_to_user(user)
    shared_with_group_links.preload_shared_with_groups.filter { |link| Ability.allowed?(user, :read_group, link.shared_with_group) }
  end

  def enforced_runner_token_expiration_interval
    all_parent_groups = Gitlab::ObjectHierarchy.new(Group.where(id: id)).ancestors
    all_group_settings = NamespaceSetting.where(namespace_id: all_parent_groups)
    group_interval = all_group_settings.where.not(subgroup_runner_token_expiration_interval: nil).minimum(:subgroup_runner_token_expiration_interval)&.seconds

    [
      Gitlab::CurrentSettings.group_runner_token_expiration_interval&.seconds,
      group_interval
    ].compact.min
  end

  def work_items_feature_flag_enabled?
    feature_flag_enabled_for_self_or_ancestor?(:work_items)
  end

  def work_items_beta_feature_flag_enabled?
    feature_flag_enabled_for_self_or_ancestor?(:work_items_beta, type: :beta)
  end

  def work_items_alpha_feature_flag_enabled?
    feature_flag_enabled_for_self_or_ancestor?(:work_items_alpha)
  end

  def continue_indented_text_feature_flag_enabled?
    feature_flag_enabled_for_self_or_ancestor?(:continue_indented_text, type: :wip)
  end

  def glql_integration_feature_flag_enabled?
    feature_flag_enabled_for_self_or_ancestor?(:glql_integration)
  end

  def wiki_comments_feature_flag_enabled?
    feature_flag_enabled_for_self_or_ancestor?(:wiki_comments, type: :wip)
  end

  # Note: this method is overridden in EE to check the work_item_epics feature flag  which also enables this feature
  def namespace_work_items_enabled?
    ::Feature.enabled?(:namespace_level_work_items, self, type: :development)
  end

  def create_group_level_work_items_feature_flag_enabled?
    ::Feature.enabled?(:create_group_level_work_items, self, type: :wip)
  end

  def supports_lock_on_merge?
    feature_flag_enabled_for_self_or_ancestor?(:enforce_locked_labels_on_merge, type: :ops)
  end

  def usage_quotas_enabled?
    root?
  end

  def supports_saved_replies?
    false
  end

  # Check for enabled features, similar to `Project#feature_available?`
  # NOTE: We still want to keep this after removing `Namespace#feature_available?`.
  override :feature_available?
  def feature_available?(feature, user = nil)
    # when we check the :issues feature at group level we need to check the `epics` license feature instead
    feature = feature == :issues ? :epics : feature

    if ::Groups::FeatureSetting.available_features.include?(feature)
      group_feature.feature_available?(feature, user) # rubocop:disable Gitlab/FeatureAvailableUsage
    else
      super
    end
  end

  def gitlab_deploy_token
    strong_memoize(:gitlab_deploy_token) do
      deploy_tokens.gitlab_deploy_token
    end
  end

  def packages_policy_subject
    ::Packages::Policies::Group.new(self)
  end

  def dependency_proxy_for_containers_policy_subject
    ::Packages::Policies::DependencyProxy::Group.new(self)
  end

  def update_two_factor_requirement_for_members
    hierarchy_members.find_each(&:update_two_factor_requirement)
  end

  def readme_project
    projects.find_by(path: README_PROJECT_PATH)
  end
  strong_memoize_attr :readme_project

  def notification_group
    self
  end

  def group_readme
    readme_project&.repository&.readme
  end
  strong_memoize_attr :group_readme

  def hook_attrs
    {
      group_name: name,
      group_path: path,
      group_id: id,
      full_path: full_path
    }
  end

  def crm_group
    Group.id_in_ordered(traversal_ids.reverse)
      .joins(:crm_settings)
      .where.not(crm_settings: { source_group_id: nil })
      .first&.crm_settings&.source_group || root_ancestor
  end
  strong_memoize_attr :crm_group

  def crm_group?
    return true if root? && crm_settings&.source_group_id.nil?

    crm_targets.present?
  end
  strong_memoize_attr :crm_group?

  def has_issues_with_contacts?
    CustomerRelations::IssueContact.joins(:issue).where(issue: { project_id: Project.where(namespace_id: self_and_descendant_ids) }).exists?
  end

  def delete_contacts
    CustomerRelations::Contact.where(group_id: id).delete_all
  end

  def delete_organizations
    CustomerRelations::Organization.where(group_id: id).delete_all
  end

  private

  def feature_flag_enabled_for_self_or_ancestor?(feature_flag, type: :development)
    actors = [root_ancestor]
    actors << self if root_ancestor != self

    actors.any? do |actor|
      ::Feature.enabled?(feature_flag, actor, type: type)
    end
  end

  def max_member_access(user)
    Gitlab::SafeRequestLoader.execute(
      resource_key: max_member_access_for_resource_key(User),
      resource_ids: [user.id],
      default_value: Gitlab::Access::NO_ACCESS
    ) do |_|
      next {} unless user.active?

      members_with_parents(only_active_users: false).where(user_id: user.id).group(:user_id).maximum(:access_level)
    end.fetch(user.id)
  end

  def update_two_factor_requirement
    return unless saved_change_to_require_two_factor_authentication? || saved_change_to_two_factor_grace_period?

    Groups::UpdateTwoFactorRequirementForMembersWorker.perform_async(self.id)
  end

  def path_changed_hook
    system_hook_service.execute_hooks_for(self, :rename)
  end

  def should_validate_visibility_level?
    new_record? || changes.has_key?(:visibility_level)
  end

  def visibility_level_allowed_by_organization
    return if visibility_level_allowed_by_organization?

    errors.add(:visibility_level, "#{visibility} is not allowed since the organization has a #{organization.visibility} visibility.")
  end

  def visibility_level_allowed_by_parent
    return if visibility_level_allowed_by_parent?

    errors.add(:visibility_level, "#{visibility} is not allowed since the parent group has a #{parent.visibility} visibility.")
  end

  def visibility_level_allowed_by_projects
    return if visibility_level_allowed_by_projects?

    errors.add(:visibility_level, "#{visibility} is not allowed since this group contains projects with higher visibility.")
  end

  def visibility_level_allowed_by_sub_groups
    return if visibility_level_allowed_by_sub_groups?

    errors.add(:visibility_level, "#{visibility} is not allowed since there are sub-groups with higher visibility.")
  end

  def two_factor_authentication_allowed
    return unless has_parent?
    return unless require_two_factor_authentication

    return if parent_allows_two_factor_authentication?

    errors.add(:require_two_factor_authentication, _('is forbidden by a top-level group'))
  end

  def runners_token_prefix
    RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX
  end

  def top_level_group_name_not_assigned_to_pages_unique_domain
    return unless parent_id.nil?

    return unless ProjectSetting.unique_domain_exists?(path)

    # We cannot disclose the Pages unique domain, hence returning generic error message
    errors.add(:path, _('has already been taken'))
  end
end

Group.prepend_mod_with('Group')
