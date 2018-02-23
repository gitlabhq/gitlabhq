module CiCd
  class GithubSetupService
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute
      create_webhook
      setup_project_integration
    end

    private

    def create_webhook
      ::CreateGithubWebhookWorker.perform_async(project.id)
    end

    def setup_project_integration
      ::CiCd::GithubIntegrationSetupService.new(project).execute
    end
  end
end
