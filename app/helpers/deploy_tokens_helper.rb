module DeployTokensHelper
  def expand_deploy_tokens_section?(deploy_token)
    deploy_token.persisted? ||
      deploy_token.errors.present? ||
      Rails.env.test?
  end
end
