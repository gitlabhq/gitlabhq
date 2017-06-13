module Emails
  class BaseService
    def initialize(current_user, user, opts)
      @current_user = current_user
      @user = user
      @email = opts[:email]
    end
  end
end
