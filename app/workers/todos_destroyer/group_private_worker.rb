# frozen_string_literal: true

module TodosDestroyer
  class GroupPrivateWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include TodosDestroyerQueue

    def perform(group_id)
      ::Todos::Destroy::GroupPrivateService.new(group_id).execute
    end
  end
end
