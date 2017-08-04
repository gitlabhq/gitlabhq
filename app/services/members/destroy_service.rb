module Members
  class DestroyService < BaseService
    include MembersHelper

    attr_accessor :source

    def initialize(source, current_user, params = {})
      @source = source
      @current_user = current_user
      @params = params
    end

    def execute
      member = find_member!

      raise Gitlab::Access::AccessDeniedError unless can_destroy_member?(member)

      AuthorizedDestroyService.new(member, current_user).execute
    end

    private

    def find_member!
      condition = params[:user_id] ? { user_id: params[:user_id] } : { id: params[:id] }
      source.members.find_by!(condition)
    end

    def can_destroy_member?(member)
      member && can?(current_user, action_member_permission(:destroy, member), member)
    end
  end
end
