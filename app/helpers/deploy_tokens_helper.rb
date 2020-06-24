# frozen_string_literal: true

module DeployTokensHelper
  def expand_deploy_tokens_section?(deploy_token)
    deploy_token.persisted? ||
      deploy_token.errors.present? ||
      Rails.env.test?
  end

  def container_registry_enabled?(subject)
    Gitlab.config.registry.enabled &&
      can?(current_user, :read_container_image, subject)
  end

  def packages_registry_enabled?(subject)
    Gitlab.config.packages.enabled &&
      subject.feature_available?(:packages) &&
      can?(current_user, :read_package, subject)
  end
end
