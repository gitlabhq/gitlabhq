# frozen_string_literal: true

module Issuable
  class DestroyService < IssuableBaseService
    # TODO: this is to be removed once we get to rename the IssuableBaseService project param to container
    def initialize(container:, current_user: nil, params: {})
      super(container: container, current_user: current_user, params: params)
    end

    def execute(issuable)
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

    def group_for(issuable)
      if issuable.project.present?
        issuable.project.group
      else
        issuable.namespace
      end
    end

    def delete_associated_records(issuable)
      actor = group_for(issuable)

      delete_todos(actor, issuable)
      delete_label_links(actor, issuable)
    end

    def delete_todos(actor, issuable)
      issuable.run_after_commit_or_now do
        TodosDestroyer::DestroyedIssuableWorker.perform_async(issuable.id, issuable.class.name)
      end
    end

    def delete_label_links(actor, issuable)
      issuable.run_after_commit_or_now do
        Issuable::LabelLinksDestroyWorker.perform_async(issuable.id, issuable.class.name)
      end
    end
  end
end

Issuable::DestroyService.prepend_mod_with('Issuable::DestroyService')
