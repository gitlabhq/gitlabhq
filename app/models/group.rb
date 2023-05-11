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
  include Todoable

  extend ::Gitlab::Utils::Override

  README_PROJECT_PATH = 'gitlab-profile'

  def self.sti_name
    'Group'
  end

  has_many :all_group_members, -> { where(requested_at: nil) }, dependent: :destroy, as: :source, class_name: 'GroupMember' # rubocop:disable Cop/ActiveRecordDependent
  has_many :group_members, -> { where(requested_at: nil).where.not(members: { access_level: Gitlab::Access::MINIMAL_ACCESS }) }, dependent: :destroy, as: :source # rubocop:disable Cop/ActiveRecordDependent
  has_many :namespace_members, -> { where(requested_at: nil).where.not(members: { access_level: Gitlab::Access::MINIMAL_ACCESS }).unscope(where: %i[source_id source_type]) },
    foreign_key: :member_namespace_id, inverse_of: :group, class_name: 'GroupMember'
  alias_method :members, :group_members

  has_many :users, through: :group_members
  has_many :owners,
    -> { where(members: { access_level: Gitlab::Access::OWNER }) },
    through: :group_members,
    source: :user

  has_many :requesters, -> { where.not(requested_at: nil) }, dependent: :destroy, as: :source, class_name: 'GroupMember' # rubocop:disable Cop/ActiveRecordDependent
  has_many :namespace_requesters, -> { where.not(requested_at: nil).unscope(where: %i[source_id source_type]) },
    foreign_key: :member_namespace_id, inverse_of: :group, class_name: 'GroupMember'

  has_many :members_and_requesters, as: :source, class_name: 'GroupMember'
  has_many :namespace_members_and_requesters, -> { unscope(where: %i[source_id source_type]) },
    foreign_key: :member_namespace_id, inverse_of: :group, class_name: 'GroupMember'

  has_many :milestones
  has_many :integrations
  has_many :shared_group_links, foreign_key: :shared_with_group_id, class_name: 'GroupGroupLink'
  has_many :shared_with_group_links, foreign_key: :shared_group_id, class_name: 'GroupGroupLink' do
    def of_ancestors
      group = proxy_association.owner

      return GroupGroupLink.none unless group.has_parent?

      GroupGroupLink.where(shared_group_id: group.ancestors.reorder(nil).select(:id))
    end

    def of_ancestors_and_self
      group = proxy_association.owner

      source_ids =
        if group.has_parent?
          group.self_and_ancestors.reorder(nil).select(:id)
        else
          group.id
        end

      GroupGroupLink.where(shared_group_id: source_ids)
    end
  end
  has_many :shared_groups, through: :shared_group_links, source: :shared_group
  has_many :shared_with_groups, through: :shared_with_group_links, source: :shared_with_group
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
  has_many :organizations, class_name: 'CustomerRelations::Organization', inverse_of: :group, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
  has_many :contacts, class_name: 'CustomerRelations::Contact', inverse_of: :group, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  has_many :cluster_groups, class_name: 'Clusters::Group'
  has_many :clusters, through: :cluster_groups, class_name: 'Clusters::Cluster'

  has_many :container_repositories, through: :projects

  has_many :todos

  has_one :import_export_upload

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

  delegate :prevent_sharing_groups_outside_hierarchy, :new_user_signups_cap, :setup_for_company, :jobs_to_be_done, to: :namespace_settings
  delegate :runner_token_expiration_interval, :runner_token_expiration_interval=, :runner_token_expiration_interval_human_readable, :runner_token_expiration_interval_human_readable=, to: :namespace_settings, allow_nil: true
  delegate :subgroup_runner_token_expiration_interval, :subgroup_runner_token_expiration_interval=, :subgroup_runner_token_expiration_interval_human_readable, :subgroup_runner_token_expiration_interval_human_readable=, to: :namespace_settings, allow_nil: true
  delegate :project_runner_token_expiration_interval, :project_runner_token_expiration_interval=, :project_runner_token_expiration_interval_human_readable, :project_runner_token_expiration_interval_human_readable=, to: :namespace_settings, allow_nil: true

  has_one :crm_settings, class_name: 'Group::CrmSettings', inverse_of: :group

  accepts_nested_attributes_for :variables, allow_destroy: true
  accepts_nested_attributes_for :group_feature, update_only: true

  validate :visibility_level_allowed_by_projects
  validate :visibility_level_allowed_by_sub_groups
  validate :visibility_level_allowed_by_parent
  validate :two_factor_authentication_allowed
  validates :variables, nested_attributes_duplicates: { scope: :environment_scope }

  validates :two_factor_grace_period, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validates :name,
            html_safety: true,
            format: { with: Gitlab::Regex.group_name_regex,
                      message: Gitlab::Regex.group_name_regex_message },
            if: :name_changed?

  validates :group_feature, presence: true

  add_authentication_token_field :runners_token,
                                 encrypted: -> { Feature.enabled?(:groups_tokens_optional_encryption) ? :optional : :required },
                                 format_with_prefix: :runners_token_prefix,
                                 require_prefix_for_validation: true

  after_create :post_create_hook
  after_create -> { create_or_load_association(:group_feature) }
  after_update :path_changed_hook, if: :saved_change_to_path?
  after_destroy :post_destroy_hook
  after_commit :update_two_factor_requirement

  scope :with_users, -> { includes(:users) }

  scope :with_onboarding_progress, -> { joins(:onboarding_progress) }

  scope :by_id, ->(groups) { where(id: groups) }

  scope :by_ids_or_paths, -> (ids, paths) do
    return by_id(ids) unless paths.present?

    ids_by_full_path = Route
      .for_routable_type(Namespace.name)
      .where('LOWER(routes.path) IN (?)', paths.map(&:downcase))
      .select(:namespace_id)

    Group.from_union([by_id(ids), by_id(ids_by_full_path), where('LOWER(path) IN (?)', paths.map(&:downcase))])
  end

  scope :for_authorized_group_members, -> (user_ids) do
    joins(:group_members)
      .where(members: { user_id: user_ids })
      .where("access_level >= ?", Gitlab::Access::GUEST)
  end

  scope :for_authorized_project_members, -> (user_ids) do
    joins(projects: :project_authorizations)
      .where(project_authorizations: { user_id: user_ids })
  end

  scope :with_project_creation_levels, -> (project_creation_levels) do
    where(project_creation_level: project_creation_levels)
  end

  scope :project_creation_allowed, -> do
    project_creation_allowed_on_levels = [
      ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS,
      ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS,
      nil
    ]

    # When the value of application_settings.default_project_creation is set to `NO_ONE_PROJECT_ACCESS`,
    # it means that a `nil` value for `groups.project_creation_level` is telling us:
    # do not allow project creation in such groups.
    # ie, `nil` is a placeholder value for inheriting the value from the ApplicationSetting.
    # So we remove `nil` from the list when the application_setting's value is `NO_ONE_PROJECT_ACCESS`
    if ::Gitlab::CurrentSettings.default_project_creation == ::Gitlab::Access::NO_ONE_PROJECT_ACCESS
      project_creation_allowed_on_levels.delete(nil)
    end

    with_project_creation_levels(project_creation_allowed_on_levels)
  end

  scope :shared_into_ancestors, -> (group) do
    joins(:shared_group_links)
      .where(group_group_links: { shared_group_id: group.self_and_ancestors })
  end

  # WARNING: This method should never be used on its own
  # please do make sure the number of rows you are filtering is small
  # enough for this query
  #
  # It's a replacement for `public_or_visible_to_user` that correctly
  # supports subgroup permissions
  scope :accessible_to_user, -> (user) do
    if user
      Preloaders::GroupPolicyPreloader.new(self, user).execute

      select { |group| user.can?(:read_group, group) }
    else
      public_to_user
    end
  end

  class << self
    def sort_by_attribute(method)
      if method == 'storage_size_desc'
        # storage_size is a virtual column so we need to
        # pass a string to avoid AR adding the table name
        reorder('storage_size DESC, namespaces.id DESC')
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

    # This method can be used only if all groups have the same top-level
    # group
    def preset_root_ancestor_for(groups)
      return groups if groups.size < 2

      root = groups.first.root_ancestor
      groups.drop(1).each { |group| group.root_ancestor = root }
    end

    # Returns the ids of the passed group models where the `emails_disabled`
    # column is set to true anywhere in the ancestor hierarchy.
    def ids_with_disabled_email(groups)
      inner_groups = Group.where('id = namespaces_with_emails_disabled.id')

      inner_query = inner_groups
        .self_and_ancestors
        .where(emails_disabled: true)
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

  def web_url(only_path: nil)
    Gitlab::UrlBuilder.build(self, only_path: only_path)
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

  def visibility_level_allowed_by_parent?(level = self.visibility_level)
    return true unless parent_id && parent_id.nonzero?

    level <= parent.visibility_level
  end

  def visibility_level_allowed_by_projects?(level = self.visibility_level)
    !projects.where('visibility_level > ?', level).exists?
  end

  def visibility_level_allowed_by_sub_groups?(level = self.visibility_level)
    !children.where('visibility_level > ?', level).exists?
  end

  def visibility_level_allowed?(level = self.visibility_level)
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
    owners.include?(user)
  end

  def add_members(users, access_level, current_user: nil, expires_at: nil, tasks_to_be_done: [], tasks_project_id: nil)
    Members::Groups::CreatorService.add_members( # rubocop:disable CodeReuse/ServiceClass
      self,
      users,
      access_level,
      current_user: current_user,
      expires_at: expires_at,
      tasks_to_be_done: tasks_to_be_done,
      tasks_project_id: tasks_project_id
    )
  end

  def add_member(user, access_level, current_user: nil, expires_at: nil, ldap: false)
    Members::Groups::CreatorService.add_member( # rubocop:disable CodeReuse/ServiceClass
      self,
      user,
      access_level,
      current_user: current_user,
      expires_at: expires_at,
      ldap: ldap
    )
  end

  def add_guest(user, current_user = nil)
    add_member(user, :guest, current_user: current_user)
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

    members_with_parents.owners.exists?(user_id: user)
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
    has_owner?(user) && member_owners_excluding_project_bots.size == 1
  end

  def member_last_owner?(member)
    return member.last_owner unless member.last_owner.nil?

    last_owner?(member.user)
  end

  # Excludes non-direct owners for top-level group
  # Excludes project_bots
  def member_owners_excluding_project_bots
    if root?
      members
    else
      members_with_parents
    end.owners.merge(User.without_project_bot)
  end

  def single_blocked_owner?
    blocked_owners.size == 1
  end

  def member_last_blocked_owner?(member)
    return member.last_blocked_owner unless member.last_blocked_owner.nil?

    return false if member_owners_excluding_project_bots.any?

    single_blocked_owner? && blocked_owners.exists?(user_id: member.user)
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

  def direct_members
    GroupMember.active_without_invites_and_requests
               .non_minimal_access
               .where(source_id: id)
  end

  def authorizable_members_with_parents
    source_ids =
      if has_parent?
        self_and_ancestors.reorder(nil).select(:id)
      else
        id
      end

    group_hierarchy_members = GroupMember.where(source_id: source_ids).select(*GroupMember.cached_column_list)

    GroupMember.from_union([group_hierarchy_members,
                            members_from_self_and_ancestor_group_shares]).authorizable
  end

  def members_with_parents
    # Avoids an unnecessary SELECT when the group has no parents
    source_ids =
      if has_parent?
        self_and_ancestors.reorder(nil).select(:id)
      else
        id
      end

    group_hierarchy_members = GroupMember.active_without_invites_and_requests
                                         .non_minimal_access
                                         .where(source_id: source_ids)
                                         .select(*GroupMember.cached_column_list)

    GroupMember.from_union([group_hierarchy_members,
                            members_from_self_and_ancestor_group_shares])
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
  def direct_and_indirect_members
    GroupMember
      .active_without_invites_and_requests
      .where(source_id: self_and_hierarchy.reorder(nil).select(:id))
  end

  def direct_and_indirect_members_with_inactive
    GroupMember
      .non_request
      .non_invite
      .where(source_id: self_and_hierarchy.reorder(nil).select(:id))
  end

  def users_with_parents
    User
      .where(id: members_with_parents.select(:user_id))
      .reorder(nil)
  end

  def users_with_descendants
    User
      .where(id: members_with_descendants.select(:user_id))
      .reorder(nil)
  end

  # Returns all users that are members of the group because:
  # 1. They belong to the group
  # 2. They belong to a project that belongs to the group
  # 3. They belong to a sub-group or project in such sub-group
  # 4. They belong to an ancestor group
  def direct_and_indirect_users
    User.from_union([
                      User
                        .where(id: direct_and_indirect_members.select(:user_id))
                        .reorder(nil),
                      project_users_with_descendants
                    ])
  end

  # Returns all users (also inactive) that are members of the group because:
  # 1. They belong to the group
  # 2. They belong to a project that belongs to the group
  # 3. They belong to a sub-group or project in such sub-group
  # 4. They belong to an ancestor group
  def direct_and_indirect_users_with_inactive
    User.from_union([
                      User
                        .where(id: direct_and_indirect_members_with_inactive.select(:user_id))
                        .reorder(nil),
                      project_users_with_descendants
                    ])
  end

  def users_count
    members.count
  end

  # Returns all users that are members of projects
  # belonging to the current group or sub-groups
  def project_users_with_descendants
    User
      .joins(projects: :group)
      .where(namespaces: { id: self_and_descendants.select(:id) })
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
    return GroupMember::OWNER if user.can_admin_all_resources? && !only_concrete_membership

    max_member_access([user.id])[user.id]
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
    GroupMember.where(source_id: self_and_ancestors_ids, user_id: user.id).order(:access_level).last
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

  def export_file_exists?
    import_export_upload&.export_file_exists?
  end

  def export_file
    import_export_upload&.export_file
  end

  def export_archive_exists?
    import_export_upload&.export_archive_exists?
  end

  def adjourned_deletion?
    false
  end

  def execute_hooks(data, hooks_scope)
    # NOOP
    # TODO: group hooks https://gitlab.com/gitlab-org/gitlab/-/issues/216904
  end

  def execute_integrations(data, hooks_scope)
    # NOOP
    # TODO: group hooks https://gitlab.com/gitlab-org/gitlab/-/issues/216904
  end

  def preload_shared_group_links
    ActiveRecord::Associations::Preloader.new(
      records: [self],
      associations: { shared_with_group_links: [shared_with_group: :route] }
    ).call
  end

  def update_shared_runners_setting!(state)
    raise ArgumentError unless SHARED_RUNNERS_SETTINGS.include?(state)

    case state
    when SR_DISABLED_AND_UNOVERRIDABLE then disable_shared_runners! # also disallows override
    when SR_DISABLED_WITH_OVERRIDE, SR_DISABLED_AND_OVERRIDABLE then disable_shared_runners_and_allow_override!
    when SR_ENABLED then enable_shared_runners! # set both to true
    end
  end

  def first_owner
    owners.first || parent&.first_owner || owner
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

    ancestor_settings = ancestors.find_by(parent_id: nil).namespace_settings
    ancestor_settings.allow_mfa_for_subgroups
  end

  def has_project_with_service_desk_enabled?
    Gitlab::ServiceDesk.supported? && all_projects.service_desk_enabled.exists?
  end
  strong_memoize_attr :has_project_with_service_desk_enabled?

  def activity_path
    Gitlab::Routing.url_helpers.activity_group_path(self)
  end

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
    crm_settings&.enabled?
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

  def content_editor_on_issues_feature_flag_enabled?
    feature_flag_enabled_for_self_or_ancestor?(:content_editor_on_issues)
  end

  def work_items_feature_flag_enabled?
    feature_flag_enabled_for_self_or_ancestor?(:work_items)
  end

  def work_items_mvc_feature_flag_enabled?
    feature_flag_enabled_for_self_or_ancestor?(:work_items_mvc)
  end

  def work_items_mvc_2_feature_flag_enabled?
    feature_flag_enabled_for_self_or_ancestor?(:work_items_mvc_2)
  end

  def usage_quotas_enabled?
    ::Feature.enabled?(:usage_quotas_for_all_editions, self) && root?
  end

  # Check for enabled features, similar to `Project#feature_available?`
  # NOTE: We still want to keep this after removing `Namespace#feature_available?`.
  override :feature_available?
  def feature_available?(feature, user = nil)
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

  def update_two_factor_requirement_for_members
    direct_and_indirect_members.find_each(&:update_two_factor_requirement)
  end

  def readme_project
    projects.find_by(path: README_PROJECT_PATH)
  end
  strong_memoize_attr :readme_project

  def group_readme
    readme_project&.repository&.readme
  end
  strong_memoize_attr :group_readme

  private

  def feature_flag_enabled_for_self_or_ancestor?(feature_flag)
    actors = [root_ancestor]
    actors << self if root_ancestor != self

    actors.any? do |actor|
      ::Feature.enabled?(feature_flag, actor)
    end
  end

  def max_member_access(user_ids)
    Gitlab::SafeRequestLoader.execute(resource_key: max_member_access_for_resource_key(User),
                                      resource_ids: user_ids,
                                      default_value: Gitlab::Access::NO_ACCESS) do |user_ids|
      members_with_parents.where(user_id: user_ids).group(:user_id).maximum(:access_level)
    end
  end

  def update_two_factor_requirement
    return unless saved_change_to_require_two_factor_authentication? || saved_change_to_two_factor_grace_period?

    Groups::UpdateTwoFactorRequirementForMembersWorker.perform_async(self.id)
  end

  def path_changed_hook
    system_hook_service.execute_hooks_for(self, :rename)
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

  def members_from_self_and_ancestor_group_shares
    group_group_link_table = GroupGroupLink.arel_table
    group_member_table = GroupMember.arel_table

    source_ids =
      if has_parent?
        self_and_ancestors.reorder(nil).select(:id)
      else
        id
      end

    group_group_links_query = GroupGroupLink.where(shared_group_id: source_ids)
    cte = Gitlab::SQL::CTE.new(:group_group_links_cte, group_group_links_query)
    cte_alias = cte.table.alias(GroupGroupLink.table_name)

    # Instead of members.access_level, we need to maximize that access_level at
    # the respective group_group_links.group_access.
    member_columns = GroupMember.attribute_names.map do |column_name|
      if column_name == 'access_level'
        smallest_value_arel([cte_alias[:group_access], group_member_table[:access_level]],
                            'access_level')
      else
        group_member_table[column_name]
      end
    end

    GroupMember
      .with(cte.to_arel)
      .select(*member_columns)
      .from([group_member_table, cte.alias_to(group_group_link_table)])
      .where(group_member_table[:requested_at].eq(nil))
      .where(group_member_table[:source_id].eq(group_group_link_table[:shared_with_group_id]))
      .where(group_member_table[:source_type].eq('Namespace'))
      .where(group_member_table[:state].eq(::Member::STATE_ACTIVE))
      .non_minimal_access
  end

  def smallest_value_arel(args, column_alias)
    Arel::Nodes::As.new(
      Arel::Nodes::NamedFunction.new('LEAST', args),
      Arel::Nodes::SqlLiteral.new(column_alias))
  end

  def disable_shared_runners!
    update!(
      shared_runners_enabled: false,
      allow_descendants_override_disabled_shared_runners: false)

    group_ids = descendants
    unless group_ids.empty?
      Group.by_id(group_ids).update_all(
        shared_runners_enabled: false,
        allow_descendants_override_disabled_shared_runners: false)
    end

    all_projects.update_all(shared_runners_enabled: false)
  end

  def disable_shared_runners_and_allow_override!
    # enabled -> disabled_and_overridable
    if shared_runners_enabled?
      update!(
        shared_runners_enabled: false,
        allow_descendants_override_disabled_shared_runners: true)

      group_ids = descendants
      unless group_ids.empty?
        Group.by_id(group_ids).update_all(shared_runners_enabled: false)
      end

      all_projects.update_all(shared_runners_enabled: false)

    # disabled_and_unoverridable -> disabled_and_overridable
    else
      update!(allow_descendants_override_disabled_shared_runners: true)
    end
  end

  def enable_shared_runners!
    update!(shared_runners_enabled: true)
  end

  def runners_token_prefix
    RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX
  end
end

Group.prepend_mod_with('Group')
