# == Schema Information
#
# Table name: user_team_project_relationships
#
#  id              :integer          not null, primary key
#  project_id      :integer
#  user_team_id    :integer
#  greatest_access :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class UserTeamProjectRelationship < ActiveRecord::Base
  attr_accessible :greatest_access, :project_id, :user_team_id

  belongs_to :user_team
  belongs_to :project

  validates :project,   presence: true
  validates :user_team, presence: true
  validate :check_greatest_access

  scope :with_project, ->(project){ where(project_id: project.id) }

  def team_name
    user_team.name
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
