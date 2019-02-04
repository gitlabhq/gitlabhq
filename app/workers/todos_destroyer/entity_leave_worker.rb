# frozen_string_literal: true

module TodosDestroyer
  class EntityLeaveWorker
    include ApplicationWorker
    include TodosDestroyerQueue

    def perform(user_id, entity_id, entity_type)
      ::Todos::Destroy::EntityLeaveService.new(user_id, entity_id, entity_type).execute
    end
  end
end
