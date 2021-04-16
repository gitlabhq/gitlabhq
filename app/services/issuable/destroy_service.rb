# frozen_string_literal: true

module Issuable
  class DestroyService < IssuableBaseService
    def execute(issuable)
      if issuable.destroy
        after_destroy(issuable)
      end
    end

    private

    def after_destroy(issuable)
      delete_todos(issuable)
      issuable.update_project_counter_caches
      issuable.assignees.each(&:invalidate_cache_counts)
    end

    def group_for(issuable)
      issuable.resource_parent
    end

    def delete_todos(issuable)
      group = group_for(issuable)

      if Feature.enabled?(:destroy_issuable_todos_async, group, default_enabled: :yaml)
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

Issuable::DestroyService.prepend_if_ee('EE::Issuable::DestroyService')
