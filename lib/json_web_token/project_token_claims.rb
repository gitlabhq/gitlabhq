# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- Shared ownership
module JSONWebToken
  class ProjectTokenClaims
    def initialize(project:, user:)
      @project = project
      @user = user
    end

    def generate
      {
        namespace_id: namespace.id.to_s,
        namespace_path: namespace.full_path,
        project_id: project.id.to_s,
        project_path: project.full_path,
        user_id: user&.id.to_s,
        user_login: user&.username,
        user_email: user&.email,
        user_access_level: user_access_level
      }
    end

    private

    attr_reader :project, :user

    delegate :namespace, to: :project

    def user_access_level
      return unless user

      project.team.human_max_access(user.id)&.downcase
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
