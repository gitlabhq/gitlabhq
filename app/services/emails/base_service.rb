module Emails
  class BaseService
    def initialize(current_user, params = {})
      @current_user, @params = current_user, params.dup
      @user = params.delete(:user)
    end
  end
end
