module Members
  class DestroyService < BaseService
    include MembersHelper

    attr_accessor :source

    ALLOWED_SCOPES = %i[members requesters all]

    def initialize(source, current_user, params = {})
      @source = source
      @current_user = current_user
      @params = params
    end

    def execute(scope = :members)
      raise "scope :#{scope} is not allowed!" unless ALLOWED_SCOPES.include?(scope)

      member = find_member(scope)

      raise Gitlab::Access::AccessDeniedError if cannot_destroy_member?(member)

      AuthorizedDestroyService.new(member, current_user).execute
    end

    private

    def find_member(scope)
      case scope
      when :all
        source.members.find_by(user_id: params[:user_id]) ||
          source.requesters.find_by!(user_id: params[:user_id])
      else
        source.public_send(scope).find_by!(user_id: params[:user_id])
      end
    end

    def cannot_destroy_member?(member)
      !member || !can?(current_user, action_member_permission(:destroy, member), member)
    end
  end
end
