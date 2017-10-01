module Emails
  class BaseService
    def initialize(user, params = {})
      @user, @params = user, params.dup
    end
  end
end
