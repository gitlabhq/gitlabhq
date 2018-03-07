module CiCd
  class GithubSetupService
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute
      create_webhook
    end

    private

    def create_webhook
      ::CreateGithubWebhookWorker.perform_async(project.id)
    end
  end
end
