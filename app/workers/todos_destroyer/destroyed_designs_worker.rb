# frozen_string_literal: true

module TodosDestroyer
  class DestroyedDesignsWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include TodosDestroyerQueue

    idempotent!

    def perform(design_ids)
      ::Todos::Destroy::DesignService.new(design_ids).execute
    end
  end
end
