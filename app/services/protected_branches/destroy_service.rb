# frozen_string_literal: true

module ProtectedBranches
  class DestroyService < ProtectedBranches::BaseService
    def execute(protected_branch)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_protected_branch, protected_branch)

      protected_branch.destroy.tap do
        refresh_cache
        publish_deleted_event
      end
    end

    def publish_deleted_event
      parent_type = if project_or_group.is_a?(Project)
                      ::Repositories::ProtectedBranchDestroyedEvent::PARENT_TYPES[:project]
                    else
                      ::Repositories::ProtectedBranchDestroyedEvent::PARENT_TYPES[:group]
                    end

      ::Gitlab::EventStore.publish(
        ::Repositories::ProtectedBranchDestroyedEvent.new(data: {
          parent_id: project_or_group.id,
          parent_type: parent_type
        })
      )
    end
  end
end

ProtectedBranches::DestroyService.prepend_mod
