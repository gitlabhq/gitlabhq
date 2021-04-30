# frozen_string_literal: true

module TodosDestroyer
  class ProjectPrivateWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include TodosDestroyerQueue

    def perform(project_id)
      ::Todos::Destroy::ProjectPrivateService.new(project_id).execute
    end
  end
end
