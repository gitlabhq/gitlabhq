module Emails
  class BaseService
    def initialize(user, opts)
      @user = user
      @email = opts[:email]
    end
  end
end
