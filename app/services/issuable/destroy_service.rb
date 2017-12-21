module Issuable
  class DestroyService < IssuableBaseService
    def execute(issuable)
      TodoService.new.destroy_target(issuable) do |issuable|
        if issuable.destroy
          issuable.update_project_counter_caches
        end
      end
    end
  end
end
