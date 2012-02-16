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

  validates_uniqueness_of :user_id, :scope => [:project_id]
  validates_presence_of :user_id
  validates_presence_of :project_id

  delegate :name, :email, :to => :user, :prefix => true

  def self.bulk_import(project, user_ids, project_access, repo_access)
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

  def self.user_bulk_import(user, project_ids, project_access, repo_access)
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
    Gitlabhq::GitHost.system.new.configure do |c|
      c.update_project(project.path, project)
    end
  end

  def project_access_human
    Project.access_options.key(self.project_access)
  end

  def repo_access_human
    ""
  end
end
# == Schema Information
#
# Table name: users_projects
#
#  id             :integer         not null, primary key
#  user_id        :integer         not null
#  project_id     :integer         not null
#  created_at     :datetime
#  updated_at     :datetime
#  repo_access    :integer         default(0), not null
#  project_access :integer         default(0), not null
#

