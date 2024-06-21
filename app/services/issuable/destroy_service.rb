# frozen_string_literal: true

module Issuable
  class DestroyService < IssuableBaseService
    # TODO: this is to be removed once we get to rename the IssuableBaseService project param to container
    def initialize(container:, current_user: nil, params: {})
      super(container: container, current_user: current_user, params: params)
    end

    def execute(issuable)
      # load sync object before destroy otherwise we cannot access it for
      # deletion of label links in delete_label_links
      @synced_object_to_delete = issuable.try(:sync_object)

      before_destroy(issuable)
      after_destroy(issuable) if issuable.destroy
    end

    private

    # overriden in EE
    def before_destroy(issuable); end

    def after_destroy(issuable)
      delete_associated_records(issuable)
      issuable.update_project_counter_caches
      issuable.assignees.each(&:invalidate_cache_counts)
    end

    def delete_associated_records(issuable)
      delete_todos(issuable)
      delete_label_links(issuable)
    end

    def delete_todos(issuable)
      synced_object_to_delete = @synced_object_to_delete

      issuable.run_after_commit_or_now do
        TodosDestroyer::DestroyedIssuableWorker.perform_async(issuable.id, issuable.class.base_class.name)

        # if there is a sync object, we need to cleanup its todos as well
        next unless synced_object_to_delete

        TodosDestroyer::DestroyedIssuableWorker.perform_async(
          synced_object_to_delete.id, synced_object_to_delete.class.base_class.name
        )
      end
    end

    def delete_label_links(issuable)
      synced_object_to_delete = @synced_object_to_delete

      issuable.run_after_commit_or_now do
        Issuable::LabelLinksDestroyWorker.perform_async(issuable.id, issuable.class.base_class.name)

        # if there is a sync object, we need to cleanup its label links as well
        next unless synced_object_to_delete

        Issuable::LabelLinksDestroyWorker.perform_async(
          synced_object_to_delete.id, synced_object_to_delete.class.base_class.name
        )
      end
    end
  end
end

Issuable::DestroyService.prepend_mod_with('Issuable::DestroyService')
