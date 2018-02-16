module Members
  class CreateService < Members::BaseService
    DEFAULT_LIMIT = 100

    def execute(source)
      return error('No users specified.') if params[:user_ids].blank?

      user_ids = params[:user_ids].split(',').uniq

      return error("Too many users specified (limit is #{user_limit})") if
        user_limit && user_ids.size > user_limit

      members = source.add_users(
        user_ids,
        params[:access_level],
        expires_at: params[:expires_at],
        current_user: current_user
      )

      members.each { |member| after_execute(member: member) }

      success
    end

    private

    def user_limit
      limit = params.fetch(:limit, DEFAULT_LIMIT)

      limit && limit < 0 ? nil : limit
    end
  end
end
