module Members
  class BaseService < ::BaseService
    attr_accessor :source

    # source - The source object that respond to `#members` (e.g. project or group)
    # current_user - The user that performs the action
    # params - A hash of parameters
    def initialize(source, current_user, params = {})
      @source = source
      @current_user = current_user
      @params = params
    end

    def after_execute(**args)
      # overriden in EE::Members modules
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
  end
end
