# frozen_string_literal: true

class ProjectMember < Member
  SOURCE_TYPE = 'Project'
  SOURCE_TYPE_FORMAT = /\AProject\z/

  self.allow_legacy_sti_class = true

  belongs_to :project, foreign_key: 'source_id'

  delegate :namespace_id, to: :project

  # Make sure project member points only to project as it source
  attribute :source_type, default: SOURCE_TYPE
  validates :source_type, format: { with: SOURCE_TYPE_FORMAT }
  default_scope { where(source_type: SOURCE_TYPE) } # rubocop:disable Cop/DefaultScope

  scope :in_project, ->(project) { where(source_id: project.id) }
  scope :in_namespaces, ->(groups) do
    joins('INNER JOIN projects ON projects.id = members.source_id')
      .where(projects: { namespace_id: groups.select(:id) })
  end
  scope :with_roles, ->(roles) { where(access_level: roles) }

  class << self
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

    # For those who get to see a modal with a role dropdown, here are the options presented
    def permissible_access_level_roles(current_user, project)
      # This method is a stopgap in preparation for https://gitlab.com/gitlab-org/gitlab/-/issues/364087
      if Ability.allowed?(current_user, :manage_owners, project)
        Gitlab::Access.options_with_owner
      else
        ProjectMember.access_level_roles
      end
    end

    def permissible_access_level_roles_for_project_access_token(current_user, project)
      if Ability.allowed?(current_user, :manage_owners, project)
        Gitlab::Access.options_with_owner
      else
        max_access_level = project.team.max_member_access(current_user.id)
        return {} unless max_access_level.present?

        ProjectMember.access_level_roles.filter do |_, value|
          value <= max_access_level
        end
      end
    end

    def access_level_roles
      Gitlab::Access.options
    end
  end

  def project
    source
  end

  def holder_of_the_personal_namespace?
    project.personal_namespace_holder?(user)
  end

  private

  override :access_level_inclusion
  def access_level_inclusion
    unless access_level.in?(Gitlab::Access.all_values)
      errors.add(:access_level, "is not included in the list")
    end
  end

  # This method is overridden in the test environment, see stubbed_member.rb
  override :refresh_member_authorized_projects
  def refresh_member_authorized_projects
    return unless user

    execute_project_authorizations_refresh

    # rubocop:disable CodeReuse/ServiceClass
    # Until we compare the inconsistency rates of the new, specialized service and
    # the old approach, we still run AuthorizedProjectsWorker
    # but with some delay and lower urgency as a safety net.
    UserProjectAccessChangedService.new(user_id)
                                   .execute(priority: UserProjectAccessChangedService::LOW_PRIORITY)
    # rubocop:enable CodeReuse/ServiceClass
  end

  def execute_project_authorizations_refresh
    AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker.perform_async(project.id, user.id)
  end

  # TODO: https://gitlab.com/groups/gitlab-org/-/epics/7054
  # temporary until we can we properly remove the source columns
  override :set_member_namespace_id
  def set_member_namespace_id
    self.member_namespace_id = project&.project_namespace_id
  end

  override :post_destroy_member_hook
  def post_destroy_member_hook
    if expired?
      event_service.expired_leave_project(self.project, self.user)
    else
      event_service.leave_project(self.project, self.user)
    end

    super
  end
end

ProjectMember.prepend_mod_with('ProjectMember')
