# == Schema Information
#
# Table name: users_groups
#
#  id           :integer          not null, primary key
#  group_access :integer          not null
#  group_id     :integer          not null
#  user_id      :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class UsersGroup < ActiveRecord::Base
  include Notifiable

  GUEST     = 10
  REPORTER  = 20
  DEVELOPER = 30
  MASTER    = 40
  OWNER     = 50

  def self.group_access_roles
    {
      "Guest"     => GUEST,
      "Reporter"  => REPORTER,
      "Developer" => DEVELOPER,
      "Master"    => MASTER,
      "Owner"     => OWNER
    }
  end

  attr_accessible :group_access, :user_id

  belongs_to :user
  belongs_to :group

  scope :guests, -> { where(group_access: GUEST) }
  scope :reporters, -> { where(group_access: REPORTER) }
  scope :developers, -> { where(group_access: DEVELOPER) }
  scope :masters,  -> { where(group_access: MASTER) }
  scope :owners,  -> { where(group_access: OWNER) }

  scope :with_group, ->(group) { where(group_id: group.id) }
  scope :with_user, ->(user) { where(user_id: user.id) }

  validates :group_access, inclusion: { in: UsersGroup.group_access_roles.values }, presence: true
  validates :user_id, presence: true
  validates :group_id, presence: true
  validates :user_id, uniqueness: { scope: [:group_id], message: "already exists in group" }

  delegate :name, :username, :email, to: :user, prefix: true

  def human_access
    UsersGroup.group_access_roles.key(self.group_access)
  end
end
