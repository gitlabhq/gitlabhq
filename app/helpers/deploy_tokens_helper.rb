module DeployTokensHelper
  def expand_deploy_tokens_section?(deploy_token)
    deploy_token.persisted? ||
      deploy_token.errors.present? ||
      Rails.env.test?
  end

  def container_registry_enabled?(project)
    Gitlab.config.registry.enabled &&
      can?(current_user, :read_container_image, project)
  end
end
