# frozen_string_literal: true

class ProjectMember < Member
  SOURCE_TYPE = 'Project'

  belongs_to :project, foreign_key: 'source_id'

  delegate :namespace_id, to: :project

  # Make sure project member points only to project as it source
  default_value_for :source_type, SOURCE_TYPE
  validates :source_type, format: { with: /\AProject\z/ }
  validates :access_level, inclusion: { in: Gitlab::Access.values }
  default_scope { where(source_type: SOURCE_TYPE) } # rubocop:disable Cop/DefaultScope

  scope :in_project, ->(project) { where(source_id: project.id) }
  scope :in_namespaces, ->(groups) do
    joins('INNER JOIN projects ON projects.id = members.source_id')
      .where(projects: { namespace_id: groups.select(:id) })
  end

  scope :without_project_bots, -> do
    left_join_users
      .merge(User.without_project_bot)
  end

  class << self
    # Add users to projects with passed access option
    #
    # access can be an integer representing a access code
    # or symbol like :maintainer representing role
    #
    # Ex.
    #   add_users_to_projects(
    #     project_ids,
    #     user_ids,
    #     ProjectMember::MAINTAINER
    #   )
    #
    #   add_users_to_projects(
    #     project_ids,
    #     user_ids,
    #     :maintainer
    #   )
    #
    def add_users_to_projects(project_ids, users, access_level, current_user: nil, expires_at: nil)
      self.transaction do
        project_ids.each do |project_id|
          project = Project.find(project_id)

          Members::Projects::CreatorService.add_users( # rubocop:todo CodeReuse/ServiceClass
            project,
            users,
            access_level,
            current_user: current_user,
            expires_at: expires_at
          )
        end
      end
    end

    def truncate_teams(project_ids)
      ProjectMember.transaction do
        members = ProjectMember.where(source_id: project_ids)

        members.each do |member|
          member.destroy
        end
      end

      true
    rescue StandardError
      false
    end

    def truncate_team(project)
      truncate_teams [project.id]
    end

    def access_level_roles
      Gitlab::Access.options
    end
  end

  def project
    source
  end

  def owner?
    project.owner == user
  end

  def notifiable_options
    { project: project }
  end

  private

  def send_invite
    run_after_commit_or_now { notification_service.invite_project_member(self, @raw_invite_token) }

    super
  end

  def post_create_hook
    unless owner?
      event_service.join_project(self.project, self.user)
      run_after_commit_or_now { notification_service.new_project_member(self) }
    end

    super
  end

  def post_update_hook
    if saved_change_to_access_level?
      run_after_commit { notification_service.update_project_member(self) }
    end

    super
  end

  def post_destroy_hook
    if expired?
      event_service.expired_leave_project(self.project, self.user)
    else
      event_service.leave_project(self.project, self.user)
    end

    super
  end

  def after_accept_invite
    notification_service.accept_project_invite(self)

    super
  end

  def after_decline_invite
    notification_service.decline_project_invite(self)

    super
  end

  # rubocop: disable CodeReuse/ServiceClass
  def event_service
    EventCreateService.new
  end
  # rubocop: enable CodeReuse/ServiceClass
end

ProjectMember.prepend_mod_with('ProjectMember')
