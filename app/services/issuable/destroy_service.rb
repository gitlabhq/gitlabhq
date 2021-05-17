# frozen_string_literal: true

module Issuable
  class DestroyService < IssuableBaseService
    def execute(issuable)
      after_destroy(issuable) if issuable.destroy
    end

    private

    def after_destroy(issuable)
      delete_associated_records(issuable)
      issuable.update_project_counter_caches
      issuable.assignees.each(&:invalidate_cache_counts)
    end

    def group_for(issuable)
      issuable.resource_parent.group
    end

    def delete_associated_records(issuable)
      actor = group_for(issuable)

      delete_todos(actor, issuable)
      delete_label_links(actor, issuable)
    end

    def delete_todos(actor, issuable)
      TodosDestroyer::DestroyedIssuableWorker
        .perform_async(issuable.id, issuable.class.name)
    end

    def delete_label_links(actor, issuable)
      Issuable::LabelLinksDestroyWorker
        .perform_async(issuable.id, issuable.class.name)
    end
  end
end

Issuable::DestroyService.prepend_mod_with('Issuable::DestroyService')
