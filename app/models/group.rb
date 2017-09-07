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
  has_many :project_group_links, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :shared_projects, through: :project_group_links, source: :project
  has_many :notification_settings, dependent: :destroy, as: :source # rubocop:disable Cop/ActiveRecordDependent
  has_many :labels, class_name: 'GroupLabel'
  has_many :variables, class_name: 'Ci::GroupVariable'
  has_many :custom_attributes, class_name: 'GroupCustomAttribute'
  has_many :runner_groups, class_name: 'Ci::RunnerGroup'
  has_many :runners, through: :runner_groups, source: :runner, class_name: 'Ci::Runner'

  has_many :uploads, as: :model, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  has_many :boards
  has_many :badges, class_name: 'GroupBadge'

  accepts_nested_attributes_for :variables, allow_destroy: true

  validate :visibility_level_allowed_by_projects
  validate :visibility_level_allowed_by_sub_groups
  validate :visibility_level_allowed_by_parent
  validates :variables, variable_duplicates: true

  validates :two_factor_grace_period, presence: true, numericality: { greater_than_or_equal_to: 0 }

  add_authentication_token_field :runners_token
  before_save :ensure_runners_token

  after_create :post_create_hook
  after_destroy :post_destroy_hook
  after_save :update_two_factor_requirement
  after_update :path_changed_hook, if: :path_changed?

  class << self
    def supports_nested_groups?
      Gitlab::Database.postgresql?
    end

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

    def visible_to_user(user)
      where(id: user.authorized_groups.select(:id).reorder(nil))
    end

    def select_for_project_authorization
      if current_scope.joins_values.include?(:shared_projects)
        joins('INNER JOIN namespaces project_namespace ON project_namespace.id = projects.namespace_id')
          .where('project_namespace.share_with_group_lock = ?',  false)
          .select("projects.id AS project_id, LEAST(project_group_links.group_access, members.access_level) AS access_level")
      else
        super
      end
    end
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

  def add_users(users, access_level, current_user: nil, expires_at: nil)
    GroupMember.add_users(
      self,
      users,
      access_level,
      current_user: current_user,
      expires_at: expires_at
    )
  end

  def add_user(user, access_level, current_user: nil, expires_at: nil)
    GroupMember.add_user(
      self,
      user,
      access_level,
      current_user: current_user,
      expires_at: expires_at
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

  def add_master(user, current_user = nil)
    add_user(user, :master, current_user: current_user)
  end

  def add_owner(user, current_user = nil)
    add_user(user, :owner, current_user: current_user)
  end

  def member?(user, min_access_level = Gitlab::Access::GUEST)
    return false unless user

    max_member_access_for_user(user) >= min_access_level
  end

  def has_owner?(user)
    return false unless user

    members_with_parents.owners.where(user_id: user).any?
  end

  def has_master?(user)
    return false unless user

    members_with_parents.masters.where(user_id: user).any?
  end

  # Check if user is a last owner of the group.
  # Parent owners are ignored for nested groups.
  def last_owner?(user)
    owners.include?(user) && owners.size == 1
  end

  def post_create_hook
    Gitlab::AppLogger.info("Group \"#{name}\" was created")

    system_hook_service.execute_hooks_for(self, :create)
  end

  def post_destroy_hook
    Gitlab::AppLogger.info("Group \"#{name}\" was removed")

    system_hook_service.execute_hooks_for(self, :destroy)
  end

  def system_hook_service
    SystemHooksService.new
  end

  def refresh_members_authorized_projects(blocking: true)
    UserProjectAccessChangedService.new(user_ids_for_project_authorizations)
      .execute(blocking: blocking)
  end

  def user_ids_for_project_authorizations
    members_with_parents.pluck(:user_id)
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

  def max_member_access_for_user(user)
    return GroupMember::OWNER if user.admin?

    members_with_parents
      .where(user_id: user)
      .reorder(access_level: :desc)
      .first&.
      access_level || GroupMember::NO_ACCESS
  end

  def mattermost_team_params
    max_length = 59

    {
      name: path[0..max_length],
      display_name: name[0..max_length],
      type: public? ? 'O' : 'I' # Open vs Invite-only
    }
  end

  def secret_variables_for(ref, project)
    list_of_ids = [self] + ancestors
    variables = Ci::GroupVariable.where(group: list_of_ids)
    variables = variables.unprotected unless project.protected_for?(ref)
    variables = variables.group_by(&:group_id)
    list_of_ids.reverse.map { |group| variables[group.id] }.compact.flatten
  end

  def group_member(user)
    if group_members.loaded?
      group_members.find { |gm| gm.user_id == user.id }
    else
      group_members.find_by(user_id: user)
    end
  end

  def hashed_storage?(_feature)
    false
  end

  def refresh_project_authorizations
    refresh_members_authorized_projects(blocking: false)
  end

  private

  def update_two_factor_requirement
    return unless require_two_factor_authentication_changed? || two_factor_grace_period_changed?

    users.find_each(&:update_two_factor_requirement)
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
end
