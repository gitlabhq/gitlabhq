# frozen_string_literal: true

module DeployTokensHelper
  def expand_deploy_tokens_section?(new_deploy_token, created_deploy_token)
    created_deploy_token ||
      new_deploy_token.errors.present? ||
      Rails.env.test?
  end

  def container_registry_enabled?(group_or_project)
    return false unless ::Gitlab.config.registry.enabled

    can?(current_user, :read_container_image, group_or_project) ||
      can?(current_user, :manage_deploy_tokens, group_or_project)
  end

  def packages_registry_enabled?(group_or_project)
    return false unless ::Gitlab.config.packages.enabled

    can?(current_user, :read_package, group_or_project&.packages_policy_subject) ||
      can?(current_user, :manage_deploy_tokens, group_or_project)
  end

  def deploy_token_revoke_button_data(token:, group_or_project:)
    {
      token: token.to_json(only: [:id, :name]),
      revoke_path: revoke_deploy_token_path(group_or_project, token)
    }
  end
end
