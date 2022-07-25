# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass
class ProjectAccessTokenEntity < API::Entities::PersonalAccessToken
  include Gitlab::Routing

  expose :revoke_path do |token, options|
    project = options.fetch(:project)

    next unless project

    revoke_namespace_project_settings_access_token_path(
      id: token,
      namespace_id: project.namespace.path,
      project_id: project.path)
  end

  expose :access_level do |token, options|
    project = options.fetch(:project)

    next unless project
    next unless token.user

    project.member(token.user)&.access_level
  end
end
# rubocop: enable Gitlab/NamespacedClass
