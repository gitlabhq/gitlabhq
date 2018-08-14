# frozen_string_literal: true

module TodosDestroyer
  class ProjectPrivateWorker
    include ApplicationWorker
    include TodosDestroyerQueue

    def perform(project_id)
      ::Todos::Destroy::ProjectPrivateService.new(project_id).execute
    end
  end
end
