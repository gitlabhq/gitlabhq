# frozen_string_literal: true

module Gitlab
  class GitAccessProject < GitAccess
    extend ::Gitlab::Utils::Override

    CreationError = Class.new(StandardError)

    ERROR_MESSAGES = {
      namespace_not_found: 'The namespace you were looking for could not be found.'
    }.freeze

    override :download_ability
    def download_ability
      :download_code
    end

    override :push_ability
    def push_ability
      :push_code
    end

    private

    override :check_container!
    def check_container!
      check_namespace!
      ensure_project_on_push!

      super
    end

    def check_namespace!
      raise NotFoundError, ERROR_MESSAGES[:namespace_not_found] unless namespace_path.present?
    end

    def namespace
      @namespace ||= Namespace.find_by_full_path(namespace_path)
    end

    def ensure_project_on_push!
      return if project || deploy_key?
      return unless receive_pack? && changes == ANY && authentication_abilities.include?(:push_code)
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

      self.container = project
      user_access.container = project

      Checks::ProjectCreated.new(repository, user, protocol).add_message
    end
  end
end
