# frozen_string_literal: true

module Members
  class BaseService < ::BaseService
    # current_user - The user that performs the action
    # params - A hash of parameters
    def initialize(current_user = nil, params = {})
      @current_user = current_user
      @params = params

      # could be a string, force to an integer, part of fix
      # https://gitlab.com/gitlab-org/gitlab/-/issues/219496
      # Allow the ArgumentError to be raised if it can't be converted to an integer.
      @params[:access_level] = Integer(@params[:access_level]) if @params[:access_level]
    end

    def after_execute(args)
      # overridden in EE::Members modules
    end

    private

    def update_member_permission(member)
      case member
      when GroupMember
        :update_group_member
      when ProjectMember
        :update_project_member
      else
        raise "Unknown member type: #{member}!"
      end
    end

    def override_member_permission(member)
      case member
      when GroupMember
        :override_group_member
      when ProjectMember
        :override_project_member
      else
        raise "Unknown member type: #{member}!"
      end
    end

    def action_member_permission(action, member)
      case action
      when :update
        update_member_permission(member)
      when :override
        override_member_permission(member)
      else
        raise "Unknown action '#{action}' on #{member}!"
      end
    end

    def enqueue_delete_todos(member)
      type = member.is_a?(GroupMember) ? 'Group' : 'Project'
      # don't enqueue immediately to prevent todos removal in case of a mistake
      member.run_after_commit_or_now do
        TodosDestroyer::EntityLeaveWorker.perform_in(Todo::WAIT_FOR_DELETE, member.user_id, member.source_id, type)
      end
    end
  end
end
