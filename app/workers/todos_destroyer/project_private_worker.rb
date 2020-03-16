# frozen_string_literal: true

module TodosDestroyer
  class ProjectPrivateWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include TodosDestroyerQueue

    def perform(project_id)
      ::Todos::Destroy::ProjectPrivateService.new(project_id).execute
    end
  end
end
