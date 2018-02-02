module Projects
  class CreateFromPushService < BaseService
    attr_reader :user, :project_path, :namespace, :protocol

    def initialize(user, project_path, namespace, protocol)
      @user = user
      @project_path = project_path
      @namespace = namespace
      @protocol = protocol
    end

    def execute
      return unless user

      project = Projects::CreateService.new(user, project_params).execute

      if project.saved?
        Gitlab::Checks::ProjectCreated.new(project, user, protocol).add_message
      else
        raise Gitlab::GitAccess::ProjectCreationError, "Could not create project: #{project.errors.full_messages.join(', ')}"
      end

      project
    end

    private

    def project_params
      {
        path: project_path,
        namespace_id: namespace&.id,
        visibility_level: Gitlab::VisibilityLevel::PRIVATE
      }
    end
  end
end
