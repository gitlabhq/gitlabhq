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
      strong_memoize(:namespace) { Namespace.find_by_full_path(namespace_path) }
    end

    def namespace_path
      strong_memoize(:namespace_path) { repository_path_match[:namespace_path] }
    end

    def project_path
      strong_memoize(:project_path) { repository_path_match[:project_path] }
    end

    def repository_path_match
      strong_memoize(:repository_path_match) { repository_path&.match(Gitlab::PathRegex.full_project_git_path_regex) || {} }
    end

    def ensure_project_on_push!
      return if project || deploy_key?
      return unless receive_pack? && changes == ANY && authentication_abilities.include?(:push_code)
      return unless user&.can?(:create_projects, namespace)

      project_params = {
        path: project_path,
        namespace_id: namespace.id,
        organization_id: namespace.organization_id,
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

Gitlab::GitAccessProject.prepend_mod_with('Gitlab::GitAccessProject')
