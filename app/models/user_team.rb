# == Schema Information
#
# Table name: user_teams
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  path       :string(255)
#  owner_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class UserTeam < ActiveRecord::Base
  attr_accessible :name, :owner_id, :path

  belongs_to :owner, class_name: User

  has_many :user_team_project_relationships, dependent: :destroy
  has_many :user_team_user_relationships, dependent: :destroy

  has_many :projects, through: :user_team_project_relationships
  has_many :members,  through: :user_team_user_relationships, source: :user

  validates :name, presence: true, uniqueness: true
  validates :owner, presence: true
  validates :path, uniqueness: true, presence: true, length: { within: 1..255 },
            format: { with: Gitlab::Regex.path_regex,
                      message: "only letters, digits & '_' '-' '.' allowed. Letter should be first" }

  scope :with_member, ->(user){ joins(:user_team_user_relationships).where(user_team_user_relationships: {user_id: user.id}) }
  scope :with_project, ->(project){ joins(:user_team_project_relationships).where(user_team_project_relationships: {project_id: project})}
  scope :without_project, ->(project){ where("user_teams.id NOT IN (:ids)", ids: (a = with_project(project); a.blank? ? 0 : a))}
  scope :created_by, ->(user){ where(owner_id: user) }

  class << self
    def search query
      where("name LIKE :query OR path LIKE :query", query: "%#{query}%")
    end

    def global_id
      'GLN'
    end

    def access_roles
      UsersProject.access_roles
    end
  end

  def to_param
    path
  end

  def assign_to_projects(projects, access)
    projects.each do |project|
      assign_to_project(project, access)
    end
  end

  def assign_to_project(project, access)
    Gitlab::UserTeamManager.assign(self, project, access)
  end

  def resign_from_project(project)
    Gitlab::UserTeamManager.resign(self, project)
  end

  def add_members(users, access, group_admin)
    users.each do |user|
      add_member(user, access, group_admin)
    end
  end

  def add_member(user, access, group_admin)
    Gitlab::UserTeamManager.add_member_into_team(self, user, access, group_admin)
  end

  def remove_member(user)
    Gitlab::UserTeamManager.remove_member_from_team(self, user)
  end

  def update_membership(user, options)
    Gitlab::UserTeamManager.update_team_user_membership(self, user, options)
  end

  def update_project_access(project, permission)
    Gitlab::UserTeamManager.update_project_greates_access(self, project, permission)
  end

  def max_project_access(project)
    user_team_project_relationships.find_by_project_id(project).greatest_access
  end

  def human_max_project_access(project)
    self.class.access_roles.invert[max_project_access(project)]
  end

  def default_projects_access(member)
    user_team_user_relationships.find_by_user_id(member).permission
  end

  def human_default_projects_access(member)
    self.class.access_roles.invert[default_projects_access(member)]
  end

  def admin?(member)
    user_team_user_relationships.with_user(member).first.group_admin?
  end

end
