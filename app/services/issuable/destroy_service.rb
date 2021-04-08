# frozen_string_literal: true

module Issuable
  class DestroyService < IssuableBaseService
    def execute(issuable)
      if issuable.destroy
        delete_todos(issuable)
        issuable.update_project_counter_caches
        issuable.assignees.each(&:invalidate_cache_counts)
      end
    end

    private

    def delete_todos(issuable)
      actor = issuable.is_a?(Epic) ? issuable.resource_parent : issuable.resource_parent.group

      if Feature.enabled?(:destroy_issuable_todos_async, actor, default_enabled: :yaml)
        TodosDestroyer::DestroyedIssuableWorker
          .perform_async(issuable.id, issuable.class.name)
      else
        TodosDestroyer::DestroyedIssuableWorker
          .new
          .perform(issuable.id, issuable.class.name)
      end
    end
  end
end
