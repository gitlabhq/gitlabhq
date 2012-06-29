module Gitlab
  module APIHelpers
    def current_user
      @current_user ||= User.find_by_authentication_token(params[:private_token])
    end

    def authenticate!
      error!({'message' => '401 Unauthorized'}, 401) unless current_user
    end
  end
end
