class UsersProject < ActiveRecord::Base
  GUEST     = 10
  REPORTER  = 20
  DEVELOPER = 30
  MASTER    = 40

  belongs_to :user
  belongs_to :project

  attr_protected :project_id, :project

  after_save :update_repository
  after_destroy :update_repository
  after_create :add_to_team_hooks
  after_destroy :remove_from_team_hooks


  validates_uniqueness_of :user_id, :scope => [:project_id]
  validates_presence_of :user_id
  validates_presence_of :project_id

  delegate :name, :email, :to => :user, :prefix => true

  def add_to_team_hooks
    SystemHook.all_hooks_fire({
      event_name: "user_add_to_team",
      project_name: self.project.name,
      project_path: self.project.path,
      project_id: self.project_id,
      user_name: self.user.name,
      user_email: self.user.email,
      project_access: self.repo_access_human,
      created_at: self.created_at
    })
  end
  
  def remove_from_team_hooks
    SystemHook.all_hooks_fire({
      event_name: "user_remove_from_team",
      project_name: self.project.name,
      project_path: self.project.path,
      project_id: self.project_id,
      user_name: self.user.name,
      user_email: self.user.email,
      project_access: self.repo_access_human
    })
  end

  def self.bulk_import(project, user_ids, project_access)
    UsersProject.transaction do
      user_ids.each do |user_id|
        users_project = UsersProject.new(
          :project_access => project_access,
          :user_id => user_id
        )
        users_project.project = project
        users_project.save
      end
    end
  end

  def self.user_bulk_import(user, project_ids, project_access)
    UsersProject.transaction do
      project_ids.each do |project_id|
        users_project = UsersProject.new(
          :project_access => project_access,
        )
        users_project.project_id = project_id
        users_project.user_id = user.id
        users_project.save
      end
    end
  end

  def self.access_roles
    {
      "Guest"   => GUEST,
      "Reporter"   => REPORTER,
      "Developer" => DEVELOPER,
      "Master"  => MASTER
    }
  end

  def role_access
    project_access
  end

  def update_repository
    Gitlab::GitHost.system.new.configure do |c|
      c.update_project(project.path, project)
    end
  end

  def project_access_human
    Project.access_options.key(self.project_access)
  end

  def repo_access_human
    self.class.access_roles.invert[self.project_access]
  end
end
# == Schema Information
#
# Table name: users_projects
#
#  id             :integer(4)      not null, primary key
#  user_id        :integer(4)      not null
#  project_id     :integer(4)      not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  project_access :integer(4)      default(0), not null
#

