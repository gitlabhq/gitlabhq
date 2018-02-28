module Issuable
  class DestroyService < IssuableBaseService
    def execute(issuable)
      if issuable.destroy
        issuable.update_project_counter_caches
      end
    end
  end
end
