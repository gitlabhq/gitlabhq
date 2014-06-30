# == Schema Information
#
# Table name: users_groups
#
#  id                 :integer          not null, primary key
#  group_access       :integer          not null
#  group_id           :integer          not null
#  user_id            :integer          not null
#  created_at         :datetime
#  updated_at         :datetime
#  notification_level :integer          default(3), not null
#

class UsersGroup < ActiveRecord::Base
  include Notifiable
  include Gitlab::Access

  def self.group_access_roles
    Gitlab::Access.options_with_owner
  end

  belongs_to :user
  belongs_to :group

  scope :guests, -> { where(group_access: GUEST) }
  scope :reporters, -> { where(group_access: REPORTER) }
  scope :developers, -> { where(group_access: DEVELOPER) }
  scope :masters,  -> { where(group_access: MASTER) }
  scope :owners,  -> { where(group_access: OWNER) }

  scope :with_group, ->(group) { where(group_id: group.id) }
  scope :with_user, ->(user) { where(user_id: user.id) }

  after_create :notify_create
  after_update :notify_update

  validates :group_access, inclusion: { in: UsersGroup.group_access_roles.values }, presence: true
  validates :user_id, presence: true
  validates :group_id, presence: true
  validates :user_id, uniqueness: { scope: [:group_id], message: "already exists in group" }

  delegate :name, :username, :email, to: :user, prefix: true

  def access_field
    group_access
  end

  def notify_create
    notification_service.new_group_member(self)
  end

  def notify_update
    if group_access_changed?
      notification_service.update_group_member(self)
    end
  end

  def notification_service
    NotificationService.new
  end
end
