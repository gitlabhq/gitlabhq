require 'carrierwave/orm/activerecord'

# Contains methods common to both GitLab CE and EE.
# All EE methods should be in `EE::Group` only.
class Group < Namespace
  include EE::Group
  include Gitlab::ConfigHelper
  include Gitlab::VisibilityLevel
  include AccessRequestable
  include Referable

  has_many :group_members, -> { where(requested_at: nil) }, dependent: :destroy, as: :source, class_name: 'GroupMember'
  alias_method :members, :group_members
  has_many :users, through: :group_members
  has_many :owners,
    -> { where(members: { access_level: Gitlab::Access::OWNER }) },
    through: :group_members,
    source: :user

  has_many :requesters, -> { where.not(requested_at: nil) }, dependent: :destroy, as: :source, class_name: 'GroupMember'

  has_many :project_group_links, dependent: :destroy
  has_many :shared_projects, through: :project_group_links, source: :project
  has_many :ldap_group_links, foreign_key: 'group_id', dependent: :destroy
  has_many :hooks, dependent: :destroy, class_name: 'GroupHook'
  # We cannot simply set `has_many :audit_events, as: :entity, dependent: :destroy`
  # here since Group inherits from Namespace, the entity_type would be set to `Namespace`.
  has_many :audit_events, -> { where(entity_type: Group) }, dependent: :destroy, foreign_key: 'entity_id'
  has_many :notification_settings, dependent: :destroy, as: :source

  validate :avatar_type, if: ->(user) { user.avatar.present? && user.avatar_changed? }
  validate :visibility_level_allowed_by_projects

  validates :avatar, file_size: { maximum: 200.kilobytes.to_i }

  mount_uploader :avatar, AvatarUploader

  after_create :post_create_hook
  after_destroy :post_destroy_hook

  scope :where_group_links_with_provider, ->(provider) do
    joins(:ldap_group_links).where(ldap_group_links: { provider: provider })
  end

  class << self
    # Searches for groups matching the given query.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query - The search query as a String
    #
    # Returns an ActiveRecord::Relation.
    def search(query)
      table   = Namespace.arel_table
      pattern = "%#{query}%"

      where(table[:name].matches(pattern).or(table[:path].matches(pattern)))
    end

    def sort(method)
      order_by(method)
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
  end

  def to_reference(_from_project = nil)
    "#{self.class.reference_prefix}#{name}"
  end

  def web_url
    Gitlab::Routing.url_helpers.group_url(self)
  end

  def human_name
    name
  end

  def visibility_level_field
    visibility_level
  end

  def visibility_level_allowed_by_projects
    allowed_by_projects = self.projects.where('visibility_level > ?', self.visibility_level).none?

    unless allowed_by_projects
      level_name = Gitlab::VisibilityLevel.level_name(visibility_level).downcase
      self.errors.add(:visibility_level, "#{level_name} is not allowed since there are projects with higher visibility.")
    end

    allowed_by_projects
  end

  def avatar_url(size = nil)
    if self[:avatar].present?
      [gitlab_config.url, avatar.url].join
    end
  end

  def add_users(user_ids, access_level, current_user: nil, skip_notification: false, expires_at: nil)
    user_ids.each do |user_id|
      Member.add_user(
        self.group_members,
        user_id,
        access_level,
        current_user: current_user,
        skip_notification: skip_notification,
        expires_at: expires_at
      )
    end
  end

  def add_user(user, access_level, current_user: nil, skip_notification: false, expires_at: nil)
    add_users([user], access_level, current_user: current_user, skip_notification: skip_notification, expires_at: expires_at)
  end

  def add_owner(user, current_user = nil, skip_notification: false)
    add_user(user, Gitlab::Access::OWNER, current_user: current_user, skip_notification: skip_notification)
  end

  def add_guest(user, current_user = nil)
    add_user(user, Gitlab::Access::GUEST, current_user: current_user)
  end

  def add_reporter(user, current_user = nil)
    add_user(user, Gitlab::Access::REPORTER, current_user: current_user)
  end

  def add_developer(user, current_user = nil)
    add_user(user, Gitlab::Access::DEVELOPER, current_user: current_user)
  end

  def add_master(user, current_user = nil)
    add_user(user, Gitlab::Access::MASTER, current_user: current_user)
  end

  def has_owner?(user)
    owners.include?(user)
  end

  def has_master?(user)
    members.masters.where(user_id: user).any?
  end

  def last_owner?(user)
    has_owner?(user) && owners.size == 1
  end

  def avatar_type
    unless self.avatar.image?
      self.errors.add :avatar, "only images allowed"
    end
  end

  def human_ldap_access
    Gitlab::Access.options_with_owner.key ldap_access
  end

  # NOTE: Backwards compatibility with old ldap situation
  def ldap_cn
    ldap_group_links.first.try(:cn)
  end

  def ldap_access
    ldap_group_links.first.try(:group_access)
  end

  def ldap_synced?
    Gitlab.config.ldap.enabled && ldap_cn.present?
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

  def first_non_empty_project
    projects.detect{ |project| !project.empty_repo? }
  end
end
