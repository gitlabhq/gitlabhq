# == Schema Information
#
# Table name: users_projects
#
#  id             :integer          not null, primary key
#  user_id        :integer          not null
#  project_id     :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  project_access :integer          default(0), not null
#

class UsersProject < ActiveRecord::Base
  include GitHost

  GUEST     = 10
  REPORTER  = 20
  DEVELOPER = 30
  MASTER    = 40

  attr_accessible :user, :user_id, :project_access

  belongs_to :user
  belongs_to :project

  after_save :update_repository
  after_destroy :update_repository

  validates :user, presence: true
  validates :user_id, uniqueness: { :scope => [:project_id], message: "already exists in project" }
  validates :project_access, inclusion: { in: [GUEST, REPORTER, DEVELOPER, MASTER] }, presence: true
  validates :project, presence: true

  delegate :name, :email, to: :user, prefix: true

  class << self
    def import_team(source_project, target_project)
      UsersProject.without_repository_callback do
        UsersProject.transaction do
          team = source_project.users_projects.all

          team.each do |tm|
            # Skip if user already present in team
            next if target_project.users.include?(tm.user)

            new_tm = tm.dup
            new_tm.id = nil
            new_tm.project_id = target_project.id
            new_tm.save
          end
        end
      end

      target_project.update_repository
      true
    rescue
      false
    end

    def without_repository_callback
      UsersProject.skip_callback(:destroy, :after, :update_repository)
      yield
      UsersProject.set_callback(:destroy, :after, :update_repository)
    end

    def bulk_delete(project, user_ids)
      UsersProject.transaction do
        UsersProject.where(:user_id => user_ids, :project_id => project.id).each do |users_project|
          users_project.destroy
        end
      end
    end

    def bulk_update(project, user_ids, project_access)
      UsersProject.transaction do
        UsersProject.where(:user_id => user_ids, :project_id => project.id).each do |users_project|
          users_project.project_access = project_access
          users_project.save
        end
      end
    end

    def bulk_import(project, user_ids, project_access)
      UsersProject.transaction do
        user_ids.each do |user_id|
          users_project = UsersProject.new(
            project_access: project_access,
            user_id: user_id
          )
          users_project.project = project
          users_project.save
        end
      end
    end

    def user_bulk_import(user, project_ids, project_access)
      UsersProject.transaction do
        project_ids.each do |project_id|
          users_project = UsersProject.new(
            project_access: project_access,
          )
          users_project.project_id = project_id
          users_project.user_id = user.id
          users_project.save
        end
      end
    end

    def access_roles
      {
        "Guest"     => GUEST,
        "Reporter"  => REPORTER,
        "Developer" => DEVELOPER,
        "Master"    => MASTER
      }
    end
  end

  def role_access
    project_access
  end

  def update_repository
    git_host.update_repository(project)
  end

  def project_access_human
    Project.access_options.key(self.project_access)
  end

  def repo_access_human
    self.class.access_roles.invert[self.project_access]
  end
end
