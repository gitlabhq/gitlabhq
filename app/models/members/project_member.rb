class ProjectMember < Member
  SOURCE_TYPE = 'Project'

  include Gitlab::ShellAdapter

  belongs_to :project, class_name: 'Project', foreign_key: 'source_id'

  # Make sure project member points only to project as it source
  default_value_for :source_type, SOURCE_TYPE
  validates_format_of :source_type, with: /\AProject\z/
  validates :access_level, inclusion: { in: Gitlab::Access.values }
  default_scope { where(source_type: SOURCE_TYPE) }

  scope :in_project, ->(project) { where(source_id: project.id) }

  before_destroy :delete_member_todos

  class << self
    # Add users to project teams with passed access option
    #
    # access can be an integer representing a access code
    # or symbol like :master representing role
    #
    # Ex.
    #   add_users_to_projects(
    #     project_ids,
    #     user_ids,
    #     ProjectMember::MASTER
    #   )
    #
    #   add_users_to_projects(
    #     project_ids,
    #     user_ids,
    #     :master
    #   )
    #
    def add_users_to_projects(project_ids, user_ids, access, current_user = nil)
      access_level = if roles_hash.has_key?(access)
                       roles_hash[access]
                     elsif roles_hash.values.include?(access.to_i)
                       access
                     else
                       raise "Non valid access"
                     end

      users = user_ids.map { |user_id| Member.user_for_id(user_id) }

      ProjectMember.transaction do
        project_ids.each do |project_id|
          project = Project.find(project_id)

          users.each do |user|
            Member.add_user(project.project_members, user, access_level, current_user)
          end
        end
      end

      true
    rescue
      false
    end

    def truncate_teams(project_ids)
      ProjectMember.transaction do
        members = ProjectMember.where(source_id: project_ids)

        members.each do |member|
          member.destroy
        end
      end

      true
    rescue
      false
    end

    def truncate_team(project)
      truncate_teams [project.id]
    end

    def roles_hash
      Gitlab::Access.sym_options
    end

    def access_level_roles
      Gitlab::Access.options
    end
  end

  def access_field
    access_level
  end

  def project
    source
  end

  def owner?
    project.owner == user
  end

  private

  def delete_member_todos
    user.todos.where(project_id: source_id).destroy_all if user
  end

  def send_invite
    notification_service.invite_project_member(self, @raw_invite_token) unless @skip_notification

    super
  end

  def post_create_hook
    unless owner?
      event_service.join_project(self.project, self.user)
      notification_service.new_project_member(self) unless @skip_notification
    end

    super
  end

  def post_update_hook
    if access_level_changed?
      notification_service.update_project_member(self)  unless @skip_notification
    end

    super
  end

  def post_destroy_hook
    event_service.leave_project(self.project, self.user)

    super
  end

  def after_accept_invite
    notification_service.accept_project_invite(self) unless @skip_notification

    super
  end

  def after_decline_invite
    notification_service.decline_project_invite(self) unless @skip_notification

    super
  end

  def event_service
    EventCreateService.new
  end
end
