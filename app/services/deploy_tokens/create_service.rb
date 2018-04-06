module DeployTokens
  class CreateService < BaseService
    def execute
      @project.deploy_tokens.create(deploy_token_params)
    end

    private

    def deploy_token_params
      params[:expires_at] = expires_at_date
      params
    end

    def expires_at_date
      params[:expires_at].presence || default_expires_at
    end

    def default_expires_at
      DeployToken::FUTURE_DATE
    end
  end
end
