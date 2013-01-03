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
  include Gitolited

  GUEST     = 10
  REPORTER  = 20
  DEVELOPER = 30
  MASTER    = 40

  attr_accessible :user, :user_id, :project_access

  belongs_to :user
  belongs_to :project

  attr_accessor :skip_git

  after_save :update_repository, unless: :skip_git?
  after_destroy :update_repository, unless: :skip_git?

  validates :user, presence: true
  validates :user_id, uniqueness: { scope: [:project_id], message: "already exists in project" }
  validates :project_access, inclusion: { in: [GUEST, REPORTER, DEVELOPER, MASTER] }, presence: true
  validates :project, presence: true

  delegate :name, :email, to: :user, prefix: true

  scope :guests, where(project_access: GUEST)
  scope :reporters, where(project_access: REPORTER)
  scope :developers, where(project_access: DEVELOPER)
  scope :masters, where(project_access: MASTER)
  scope :in_project, ->(project) { where(project_id: project.id) }

  class << self
    def add_users_into_projects(project_ids, user_ids, project_access)
      UsersProject.transaction do
        project_ids.each do |project_id|
          user_ids.each do |user_id|
            users_project = UsersProject.new(project_access: project_access, user_id: user_id)
            users_project.project_id = project_id
            users_project.skip_git = true
            users_project.save
          end
        end
        Gitlab::Gitolite.new.update_repositories(Project.where(id: project_ids))
      end

      true
    rescue
      false
    end

    def truncate_teams(project_ids)
      UsersProject.transaction do
        users_projects = UsersProject.where(project_id: project_ids)
        users_projects.each do |users_project|
          users_project.skip_git = true
          users_project.destroy
        end
        Gitlab::Gitolite.new.update_repositories(Project.where(id: project_ids))
      end

      true
    rescue
      false
    end

    def truncate_team project
      truncate_teams [project.id]
    end

    def import_team(source_project, target_project)
      source_team = source_project.users_projects.all
      target_team = target_project.users_projects.all
      target_user_ids = target_team.map(&:user_id)

      source_team.reject! do |tm|
        # Skip if user already present in team
        target_user_ids.include?(tm.user_id)
      end

      source_team.map! do |tm|
        new_tm = tm.dup
        new_tm.id = nil
        new_tm.project_id = target_project.id
        new_tm.skip_git = true
        new_tm
      end

      UsersProject.transaction do
        source_team.each do |tm|
          tm.save
        end
        target_project.update_repository
      end

      true
    rescue
      false
    end

    def bulk_delete(project, user_ids)
      UsersProject.transaction do
        UsersProject.where(user_id: user_ids, project_id: project.id).each do |users_project|
          users_project.skip_git = true
          users_project.destroy
        end

        project.update_repository
      end
    end

    def bulk_update(project, user_ids, project_access)
      UsersProject.transaction do
        UsersProject.where(user_id: user_ids, project_id: project.id).each do |users_project|
          users_project.project_access = project_access
          users_project.skip_git = true
          users_project.save
        end
        project.update_repository
      end
    end

    # TODO: depreceate in future in favor of add_users_into_projects
    def bulk_import(project, user_ids, project_access)
      add_users_into_projects([project.id], user_ids, project_access)
    end

    # TODO: depreceate in future in favor of add_users_into_projects
    def user_bulk_import(user, project_ids, project_access)
      add_users_into_projects(project_ids, [user.id], project_access)
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
    gitolite.update_repository(project)
  end

  def project_access_human
    Project.access_options.key(self.project_access)
  end

  def repo_access_human
    self.class.access_roles.invert[self.project_access]
  end

  def skip_git?
    !!@skip_git
  end
end
