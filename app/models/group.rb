# == Schema Information
#
# Table name: namespaces
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  path        :string(255)      not null
#  owner_id    :integer
#  created_at  :datetime
#  updated_at  :datetime
#  type        :string(255)
#  description :string(255)      default(""), not null
#  avatar      :string(255)
#  public      :boolean          default(FALSE)
#

require 'carrierwave/orm/activerecord'
require 'file_size_validator'

class Group < Namespace
  include Gitlab::ConfigHelper
  include Referable
  include GroupsSearch
  
  has_many :group_members, dependent: :destroy, as: :source, class_name: 'GroupMember'
  alias_method :members, :group_members
  has_many :users, through: :group_members
  has_many :project_group_links, dependent: :destroy
  has_many :shared_projects, through: :project_group_links, source: :project
  has_many :ldap_group_links, foreign_key: 'group_id', dependent: :destroy
  has_many :hooks, dependent: :destroy, class_name: 'GroupHook'

  validate :avatar_type, if: ->(user) { user.avatar.present? && user.avatar_changed? }
  validates :avatar, file_size: { maximum: 200.kilobytes.to_i }

  mount_uploader :avatar, AvatarUploader

  after_create :post_create_hook
  after_destroy :post_destroy_hook

  class << self
    def search(query)
      where("LOWER(namespaces.name) LIKE :query or LOWER(namespaces.path) LIKE :query", query: "%#{query.downcase}%")
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

    def public_and_given_groups(ids)
      where('public IS TRUE OR namespaces.id IN (?)', ids)
    end

    def visible_to_user(user)
      where(id: user.authorized_groups.select(:id).reorder(nil))
    end
  end

  def to_reference(_from_project = nil)
    "#{self.class.reference_prefix}#{name}"
  end

  def human_name
    name
  end

  def avatar_url(size = nil)
    if avatar.present?
      [gitlab_config.url, avatar.url].join
    end
  end

  def owners
    @owners ||= group_members.owners.includes(:user).map(&:user)
  end

  def add_users(user_ids, access_level, current_user = nil, skip_notification: false)
    user_ids.each do |user_id|
      Member.add_user(self.group_members, user_id, access_level, current_user, skip_notification: skip_notification)
    end
  end

  def add_user(user, access_level, current_user = nil, skip_notification: false)
    add_users([user], access_level, current_user, skip_notification: skip_notification)
  end

  def add_owner(user, current_user = nil, skip_notification: false)
    self.add_user(user, Gitlab::Access::OWNER, current_user, skip_notification: skip_notification)
  end

  def add_guest(user, current_user = nil)
    add_user(user, Gitlab::Access::GUEST, current_user)
  end

  def add_reporter(user, current_user = nil)
    add_user(user, Gitlab::Access::REPORTER, current_user)
  end

  def add_developer(user, current_user = nil)
    add_user(user, Gitlab::Access::DEVELOPER, current_user)
  end

  def add_master(user, current_user = nil)
    add_user(user, Gitlab::Access::MASTER, current_user)
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

  def public_profile?
    self.public || projects.public_only.any?
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
