module Emails
  class BaseService
    def initialize(current_user, user, opts)
      @current_user = current_user
      @user = user
      @email = opts[:email]
    end

    private

    def can_manage_emails?
      @current_user == @user || @current_user.admin?
    end
  end
end
