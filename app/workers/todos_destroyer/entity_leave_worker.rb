# frozen_string_literal: true

module TodosDestroyer
  class EntityLeaveWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include TodosDestroyerQueue

    loggable_arguments 2

    def perform(user_id, entity_id, entity_type)
      ::Todos::Destroy::EntityLeaveService.new(user_id, entity_id, entity_type).execute
    end
  end
end
