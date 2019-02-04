# frozen_string_literal: true

module TodosDestroyer
  class GroupPrivateWorker
    include ApplicationWorker
    include TodosDestroyerQueue

    def perform(group_id)
      ::Todos::Destroy::GroupPrivateService.new(group_id).execute
    end
  end
end
