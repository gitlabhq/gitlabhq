# frozen_string_literal: true

module Gitlab
  class GitAccessProject < GitAccess
    extend ::Gitlab::Utils::Override

    CreationError = Class.new(StandardError)

    private

    override :check_project!
    def check_project!(cmd)
      ensure_project_on_push!(cmd)

      super
    end

    def ensure_project_on_push!(cmd)
      return if project || deploy_key?
      return unless receive_pack?(cmd) && changes == ANY && authentication_abilities.include?(:push_code)

      namespace = Namespace.find_by_full_path(namespace_path)

      return unless user&.can?(:create_projects, namespace)

      project_params = {
        path: repository_path,
        namespace_id: namespace.id,
        visibility_level: Gitlab::VisibilityLevel::PRIVATE
      }

      project = Projects::CreateService.new(user, project_params).execute

      unless project.saved?
        raise CreationError, "Could not create project: #{project.errors.full_messages.join(', ')}"
      end

      @project = project
      user_access.project = @project

      Checks::ProjectCreated.new(repository, user, protocol).add_message
    end
  end
end
