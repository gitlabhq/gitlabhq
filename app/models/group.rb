# frozen_string_literal: true

require 'carrierwave/orm/activerecord'

class Group < Namespace
  include Gitlab::ConfigHelper
  include AfterCommitQueue
  include AccessRequestable
  include Avatarable
  include Referable
  include SelectForProjectAuthorization
  include LoadedInGroupList
  include GroupDescendant
  include TokenAuthenticatable
  include WithUploads
  include Gitlab::Utils::StrongMemoize
  include GroupAPICompatibility

  ACCESS_REQUEST_APPROVERS_TO_BE_NOTIFIED_LIMIT = 10

  has_many :group_members, -> { where(requested_at: nil) }, dependent: :destroy, as: :source # rubocop:disable Cop/ActiveRecordDependent
  alias_method :members, :group_members
  has_many :users, through: :group_members
  has_many :owners,
    -> { where(members: { access_level: Gitlab::Access::OWNER }) },
    through: :group_members,
    source: :user

  has_many :requesters, -> { where.not(requested_at: nil) }, dependent: :destroy, as: :source, class_name: 'GroupMember' # rubocop:disable Cop/ActiveRecordDependent
  has_many :members_and_requesters, as: :source, class_name: 'GroupMember'

  has_many :milestones
  has_many :shared_group_links, foreign_key: :shared_with_group_id, class_name: 'GroupGroupLink'
  has_many :shared_with_group_links, foreign_key: :shared_group_id, class_name: 'GroupGroupLink'
  has_many :shared_groups, through: :shared_group_links, source: :shared_group
  has_many :shared_with_groups, through: :shared_with_group_links, source: :shared_with_group
  has_many :project_group_links, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :shared_projects, through: :project_group_links, source: :project

  # Overridden on another method
  # Left here just to be dependent: :destroy
  has_many :notification_settings, dependent: :destroy, as: :source # rubocop:disable Cop/ActiveRecordDependent

  has_many :labels, class_name: 'GroupLabel'
  has_many :variables, class_name: 'Ci::GroupVariable'
  has_many :custom_attributes, class_name: 'GroupCustomAttribute'

  has_many :boards
  has_many :badges, class_name: 'GroupBadge'

  has_many :cluster_groups, class_name: 'Clusters::Group'
  has_many :clusters, through: :cluster_groups, class_name: 'Clusters::Cluster'

  has_many :container_repositories, through: :projects

  has_many :todos

  has_one :import_export_upload

  accepts_nested_attributes_for :variables, allow_destroy: true

  validate :visibility_level_allowed_by_projects
  validate :visibility_level_allowed_by_sub_groups
  validate :visibility_level_allowed_by_parent
  validates :variables, variable_duplicates: true

  validates :two_factor_grace_period, presence: true, numericality: { greater_than_or_equal_to: 0 }

  add_authentication_token_field :runners_token, encrypted: -> { Feature.enabled?(:groups_tokens_optional_encryption, default_enabled: true) ? :optional : :required }

  after_create :post_create_hook
  after_destroy :post_destroy_hook
  after_save :update_two_factor_requirement
  after_update :path_changed_hook, if: :saved_change_to_path?

  scope :with_users, -> { includes(:users) }

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

    def reference_prefix
      User.reference_prefix
    end

    def reference_pattern
      User.reference_pattern
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
          .where('project_namespace.share_with_group_lock = ?', false)
          .select("projects.id AS project_id, LEAST(project_group_links.group_access, members.access_level) AS access_level")
      else
        super
      end
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

  def notification_email_for(user)
    # Finds the closest notification_setting with a `notification_email`
    notification_settings = notification_settings_for(user, hierarchy_order: :asc)
    notification_settings.find { |n| n.notification_email.present? }&.notification_email
  end

  def to_reference(_from = nil, full: nil)
    "#{self.class.reference_prefix}#{full_path}"
  end

  def web_url
    Gitlab::Routing.url_helpers.group_canonical_url(self)
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

  def add_users(users, access_level, current_user: nil, expires_at: nil)
    GroupMember.add_users(
      self,
      users,
      access_level,
      current_user: current_user,
      expires_at: expires_at
    )
  end

  def add_user(user, access_level, current_user: nil, expires_at: nil, ldap: false)
    GroupMember.add_user(
      self,
      user,
      access_level,
      current_user: current_user,
      expires_at: expires_at,
      ldap: ldap
    )
  end

  def add_guest(user, current_user = nil)
    add_user(user, :guest, current_user: current_user)
  end

  def add_reporter(user, current_user = nil)
    add_user(user, :reporter, current_user: current_user)
  end

  def add_developer(user, current_user = nil)
    add_user(user, :developer, current_user: current_user)
  end

  def add_maintainer(user, current_user = nil)
    add_user(user, :maintainer, current_user: current_user)
  end

  # @deprecated
  alias_method :add_master, :add_maintainer

  def add_owner(user, current_user = nil)
    add_user(user, :owner, current_user: current_user)
  end

  def member?(user, min_access_level = Gitlab::Access::GUEST)
    return false unless user

    max_member_access_for_user(user) >= min_access_level
  end

  def has_owner?(user)
    return false unless user

    members_with_parents.owners.exists?(user_id: user)
  end

  def has_maintainer?(user)
    return false unless user

    members_with_parents.maintainers.exists?(user_id: user)
  end

  def has_container_repository_including_subgroups?
    ::ContainerRepository.for_group_and_its_subgroups(self).exists?
  end

  # @deprecated
  alias_method :has_master?, :has_maintainer?

  # Check if user is a last owner of the group.
  def last_owner?(user)
    has_owner?(user) && members_with_parents.owners.size == 1
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
  def refresh_members_authorized_projects(blocking: true)
    UserProjectAccessChangedService.new(user_ids_for_project_authorizations)
      .execute(blocking: blocking)
  end
  # rubocop: enable CodeReuse/ServiceClass

  def user_ids_for_project_authorizations
    members_with_parents.pluck(:user_id)
  end

  def self_and_ancestors_ids
    strong_memoize(:self_and_ancestors_ids) do
      self_and_ancestors.pluck(:id)
    end
  end

  def members_with_parents
    # Avoids an unnecessary SELECT when the group has no parents
    source_ids =
      if parent_id
        self_and_ancestors.reorder(nil).select(:id)
      else
        id
      end

    GroupMember
      .active_without_invites_and_requests
      .where(source_id: source_ids)
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

  # Returns all users that are members of projects
  # belonging to the current group or sub-groups
  def project_users_with_descendants
    User
      .joins(projects: :group)
      .where(namespaces: { id: self_and_descendants.select(:id) })
  end

  def max_member_access_for_user(user)
    return GroupMember::NO_ACCESS unless user

    return GroupMember::OWNER if user.admin?

    max_member_access = members_with_parents.where(user_id: user)
                                            .reorder(access_level: :desc)
                                            .first
                                            &.access_level

    max_member_access || max_member_access_for_user_from_shared_groups(user) || GroupMember::NO_ACCESS
  end

  def mattermost_team_params
    max_length = 59

    {
      name: path[0..max_length],
      display_name: name[0..max_length],
      type: public? ? 'O' : 'I' # Open vs Invite-only
    }
  end

  def ci_variables_for(ref, project)
    list_of_ids = [self] + ancestors
    variables = Ci::GroupVariable.where(group: list_of_ids)
    variables = variables.unprotected unless project.protected_for?(ref)
    variables = variables.group_by(&:group_id)
    list_of_ids.reverse.flat_map { |group| variables[group.id] }.compact
  end

  def group_member(user)
    if group_members.loaded?
      group_members.find { |gm| gm.user_id == user.id }
    else
      group_members.find_by(user_id: user)
    end
  end

  def highest_group_member(user)
    GroupMember.where(source_id: self_and_ancestors_ids, user_id: user.id).order(:access_level).last
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
    refresh_members_authorized_projects(blocking: false)
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
    members.owners.order_recent_sign_in.limit(ACCESS_REQUEST_APPROVERS_TO_BE_NOTIFIED_LIMIT)
  end

  def supports_events?
    false
  end

  def export_file_exists?
    export_file&.file
  end

  def export_file
    import_export_upload&.export_file
  end

  private

  def update_two_factor_requirement
    return unless saved_change_to_require_two_factor_authentication? || saved_change_to_two_factor_grace_period?

    members_with_descendants.find_each(&:update_two_factor_requirement)
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

  def max_member_access_for_user_from_shared_groups(user)
    return unless Feature.enabled?(:share_group_with_group)

    group_group_link_table = GroupGroupLink.arel_table
    group_member_table = GroupMember.arel_table

    group_group_links_query = GroupGroupLink.where(shared_group_id: self_and_ancestors_ids)
    cte = Gitlab::SQL::CTE.new(:group_group_links_cte, group_group_links_query)

    link = GroupGroupLink
             .with(cte.to_arel)
             .from([group_member_table, cte.alias_to(group_group_link_table)])
             .where(group_member_table[:user_id].eq(user.id))
             .where(group_member_table[:source_id].eq(group_group_link_table[:shared_with_group_id]))
             .reorder(Arel::Nodes::Descending.new(group_group_link_table[:group_access]))
             .first

    link&.group_access
  end

  def self.groups_including_descendants_by(group_ids)
    Gitlab::ObjectHierarchy
      .new(Group.where(id: group_ids))
      .base_and_descendants
  end
end

Group.prepend_if_ee('EE::Group')
