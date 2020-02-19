# frozen_string_literal: true

module TodosDestroyer
  class GroupPrivateWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include TodosDestroyerQueue

    def perform(group_id)
      ::Todos::Destroy::GroupPrivateService.new(group_id).execute
    end
  end
end
