# frozen_string_literal: true

module ProtectedBranches
  class CreateService < ProtectedBranches::BaseService
    def execute(skip_authorization: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || authorized?

      save_protected_branch

      refresh_cache

      protected_branch
    end

    def authorized?
      can?(current_user, :create_protected_branch, protected_branch)
    end

    private

    def save_protected_branch
      protected_branch.save.tap do
        # Refresh all_protected_branches association as it is not automatically updated
        project_or_group.all_protected_branches.reset if project_or_group.is_a?(Project)

        publish_created_event
      end
    end

    def publish_created_event
      return unless protected_branch.id

      parent_type = if project_or_group.is_a?(Project)
                      ::Repositories::ProtectedBranchCreatedEvent::PARENT_TYPES[:project]
                    else
                      ::Repositories::ProtectedBranchCreatedEvent::PARENT_TYPES[:group]
                    end

      ::Gitlab::EventStore.publish(
        ::Repositories::ProtectedBranchCreatedEvent.new(data: {
          protected_branch_id: protected_branch.id,
          parent_id: project_or_group.id,
          parent_type: parent_type
        })
      )
    end

    def protected_branch
      @protected_branch ||= project_or_group.protected_branches.new(params)
    end
  end
end

ProtectedBranches::CreateService.prepend_mod
