class UserTeamGroupRelationship < ActiveRecord::Base
  attr_accessible :group_id, :user_team_id, :greatest_access

  belongs_to :group
  belongs_to :user_team

  validate :group, presence: true
  validate :user_team, presence: true
  validate :check_greatest_access

  scope :with_group, ->(group) {where(group_id: group)}

  def human_max_access
    UserTeam.access_roles.key(greatest_access)
  end

  private

  def check_greatest_access
    errors.add(:base, :incorrect_access_code) unless correct_access?
  end

  def correct_access?
    return false if greatest_access.blank?
    return true if UsersProject.access_roles.has_value?(greatest_access)
    false
  end
end
