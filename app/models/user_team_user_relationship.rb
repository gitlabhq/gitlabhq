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
end
