module TodosDestroyer
  class PrivateFeaturesWorker
    include ApplicationWorker
    include TodosDestroyerQueue

    def perform(project_id, user_id = nil)
      ::Todos::Destroy::PrivateFeaturesService.new(project_id, user_id).execute
    end
  end
end
