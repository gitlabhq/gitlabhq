module Emails
  class BaseService
    def initialize(current_user, opts)
      @current_user = current_user
      @user = opts.delete(:user)
      @email = opts[:email]
    end
  end
end
