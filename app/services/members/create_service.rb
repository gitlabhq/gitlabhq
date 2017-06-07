module Members
  class CreateService < BaseService
    DEFAULT_LIMIT = 100

    def initialize(source, current_user, params = {})
      @source = source
      @current_user = current_user
      @params = params
      @error = nil
    end

    def execute
      return error('No users specified.') if params[:user_ids].blank?

      user_ids = params[:user_ids].split(',').uniq

      return error("Too many users specified (limit is #{user_limit})") if
        user_limit && user_ids.size > user_limit

      members = @source.add_users(
        user_ids,
        params[:access_level],
        expires_at: params[:expires_at],
        current_user: current_user
      )

      members.compact.each do |member|
        AuditEventService.new(@current_user, @source, action: :create)
          .for_member(member).security_event
      end

      success
    end

    private

    def user_limit
      limit = params.fetch(:limit, DEFAULT_LIMIT)

      limit && limit < 0 ? nil : limit
    end
  end
end
