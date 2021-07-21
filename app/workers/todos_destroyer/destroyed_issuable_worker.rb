# frozen_string_literal: true

module TodosDestroyer
  class DestroyedIssuableWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include TodosDestroyerQueue

    tags :exclude_from_kubernetes

    idempotent!

    def perform(target_id, target_type)
      ::Todos::Destroy::DestroyedIssuableService.new(target_id, target_type).execute
    end
  end
end
