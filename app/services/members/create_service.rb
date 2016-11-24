module Members
  class CreateService < BaseService
    def execute
      return false if params[:user_ids].blank?

      project.team.add_users(
        params[:user_ids].split(','),
        params[:access_level],
        expires_at: params[:expires_at],
        current_user: current_user
      )

      true
    end
  end
end
