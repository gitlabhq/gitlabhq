module DeployTokens
  class CreateService < BaseService
    def execute
      @project.deploy_tokens.build(params).tap(&:save)
    end
  end
end
