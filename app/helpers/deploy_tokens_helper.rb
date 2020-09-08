# frozen_string_literal: true

module DeployTokensHelper
  def expand_deploy_tokens_section?(deploy_token)
    deploy_token.persisted? ||
      deploy_token.errors.present? ||
      Rails.env.test?
  end

  def container_registry_enabled?(group_or_project)
    Gitlab.config.registry.enabled &&
      can?(current_user, :read_container_image, group_or_project)
  end

  def packages_registry_enabled?(group_or_project)
    Gitlab.config.packages.enabled &&
      can?(current_user, :read_package, group_or_project)
  end
end
