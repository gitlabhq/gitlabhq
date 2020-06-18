# frozen_string_literal: true

module TodosDestroyer
  class EntityLeaveWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include TodosDestroyerQueue

    loggable_arguments 2

    def perform(user_id, entity_id, entity_type)
      ::Todos::Destroy::EntityLeaveService.new(user_id, entity_id, entity_type).execute
    end
  end
end
