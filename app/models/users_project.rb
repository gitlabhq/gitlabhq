# == Schema Information
#
# Table name: users_projects
#
#  id                 :integer          not null, primary key
#  user_id            :integer          not null
#  project_id         :integer          not null
#  created_at         :datetime
#  updated_at         :datetime
#  project_access     :integer          default(0), not null
#  notification_level :integer          default(3), not null
#

class UsersProject < ActiveRecord::Base
  include Gitlab::ShellAdapter
  include Notifiable
  include Gitlab::Access

  belongs_to :user
  belongs_to :project

  validates :user, presence: true
  validates :user_id, uniqueness: { scope: [:project_id], message: "already exists in project" }
  validates :project_access, inclusion: { in: Gitlab::Access.values }, presence: true
  validates :project, presence: true

  delegate :name, :username, :email, to: :user, prefix: true

  scope :guests, -> { where(project_access: GUEST) }
  scope :reporters, -> { where(project_access: REPORTER) }
  scope :developers, -> { where(project_access: DEVELOPER) }
  scope :masters,  -> { where(project_access: MASTER) }

  scope :in_project, ->(project) { where(project_id: project.id) }
  scope :in_projects, ->(projects) { where(project_id: projects.map { |p| p.id }) }
  scope :with_user, ->(user) { where(user_id: user.id) }

  after_create :post_create_hook
  after_update :post_update_hook
  after_destroy :post_destroy_hook

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
            users_project.save
          end
        end
      end

      true
    rescue
      false
    end

    def truncate_teams(project_ids)
      UsersProject.transaction do
        users_projects = UsersProject.where(project_id: project_ids)
        users_projects.each do |users_project|
          users_project.destroy
        end
      end

      true
    rescue
      false
    end

    def truncate_team project
      truncate_teams [project.id]
    end

    def roles_hash
      Gitlab::Access.sym_options
    end

    def access_roles
      Gitlab::Access.options
    end
  end

  def access_field
    project_access
  end

  def owner?
    project.owner == user
  end

  def post_create_hook
    Event.create(
      project_id: self.project.id,
      action: Event::JOINED,
      author_id: self.user.id
    )

    notification_service.new_team_member(self) unless owner?
    system_hook_service.execute_hooks_for(self, :create)
  end

  def post_update_hook
    notification_service.update_team_member(self) if self.project_access_changed?
  end

  def post_destroy_hook
    Event.create(
      project_id: self.project.id,
      action: Event::LEFT,
      author_id: self.user.id
    )

    system_hook_service.execute_hooks_for(self, :destroy)
  end

  def notification_service
    NotificationService.new
  end

  def system_hook_service
    SystemHooksService.new
  end
end
