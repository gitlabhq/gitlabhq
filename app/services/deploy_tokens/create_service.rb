module DeployTokens
  class CreateService < BaseService
    def execute
      @project.deploy_tokens.create(params)
    end
  end
end
