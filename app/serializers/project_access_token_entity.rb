# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass
class ProjectAccessTokenEntity < AccessTokenEntityBase
  include Gitlab::Routing

  expose :revoke_path do |token, options|
    project = options.fetch(:project)

    next unless project

    revoke_namespace_project_settings_access_token_path(
      id: token,
      namespace_id: project.namespace.full_path,
      project_id: project.path)
  end

  expose :rotate_path do |token, options|
    project = options.fetch(:project)

    next unless project

    rotate_namespace_project_settings_access_token_path(
      id: token,
      namespace_id: project.namespace.full_path,
      project_id: project.path
    )
  end

  expose :role do |token, options|
    project = options.fetch(:project)

    next unless project
    next unless token.user

    project.member(token.user)&.human_access
  end
end
# rubocop: enable Gitlab/NamespacedClass
