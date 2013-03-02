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

  delegate :name, :username, :email, to: :user, prefix: true

  scope :guests, where(project_access: GUEST)
  scope :reporters, where(project_access: REPORTER)
  scope :developers, where(project_access: DEVELOPER)
  scope :masters, where(project_access: MASTER)

  scope :in_project, ->(project) { where(project_id: project.id) }
  scope :in_projects, ->(projects) { where(project_id: project_ids) }
  scope :with_user, ->(user) { where(user_id: user.id) }

  class << self

    # Add users to project teams with passed access option
    #
    # access can be an integer representing a access code
    # or symbol like :master representing role
    #
    # Ex.
    #   add_users_into_projects(
    #     project_ids,
    #     user_ids,
    #     UsersProject::MASTER
    #   )
    #
    #   add_users_into_projects(
    #     project_ids,
    #     user_ids,
    #     :master
    #   )
    #
    def add_users_into_projects(project_ids, user_ids, access)
      project_access = if roles_hash.has_key?(access)
                         roles_hash[access]
                       elsif roles_hash.values.include?(access.to_i)
                         access
                       else
                         raise "Non valid access"
                       end

      UsersProject.transaction do
        project_ids.each do |project_id|
          user_ids.each do |user_id|
            users_project = UsersProject.new(project_access: project_access, user_id: user_id)
            users_project.project_id = project_id
            users_project.skip_git = true
            users_project.save
          end
        end
      end

      GitoliteWorker.perform_async(
        :update_repositories,
        project_ids
      )

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
      end

      GitoliteWorker.perform_async(
        :update_repositories,
        project_ids
      )

      true
    rescue
      false
    end

    def truncate_team project
      truncate_teams [project.id]
    end

    def roles_hash
      {
        guest: GUEST,
        reporter: REPORTER,
        developer: DEVELOPER,
        master: MASTER
      }
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

  def update_repository
    project.update_repository
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
