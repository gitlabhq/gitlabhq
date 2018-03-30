module DeployTokensHelper
  def expand_deploy_tokens_section?(temporal_token, deploy_token)
    temporal_token.present? ||
      deploy_token.errors.present? ||
      Rails.env.test?
  end
end
