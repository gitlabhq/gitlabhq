# frozen_string_literal: true

module TodosDestroyer
  class PrivateFeaturesWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include TodosDestroyerQueue

    def perform(project_id, user_id = nil)
      ::Todos::Destroy::PrivateFeaturesService.new(project_id, user_id).execute
    end
  end
end
