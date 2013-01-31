# == Schema Information
#
# Table name: user_team_user_relationships
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  user_team_id :integer
#  group_admin  :boolean
#  permission   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class UserTeamUserRelationship < ActiveRecord::Base
  attr_accessible :group_admin, :permission, :user_id, :user_team_id

  belongs_to :user_team
  belongs_to :user

  validates :user_team, presence: true
  validates :user,      presence: true

  scope :with_user, ->(user) { where(user_id: user.id) }

  def user_name
    user.name
  end

  def access_human
    UsersProject.access_roles.invert[permission]
  end
end
