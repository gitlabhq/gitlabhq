module Members
  class CreateService < BaseService
    def initialize(source, current_user, params = {})
      @source = source
      @current_user = current_user
      @params = params
    end

    def execute
      return false if params[:user_ids].blank?

      members = @source.add_users(
        params[:user_ids].split(','),
        params[:access_level],
        expires_at: params[:expires_at],
        current_user: current_user
      )

      members.compact.each do |member|
        AuditEventService.new(@current_user, @source, action: :create)
          .for_member(member).security_event
      end

      true
    end
  end
end
