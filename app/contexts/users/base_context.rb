module Users
  class BaseContext < ::BaseContext
    attr_accessor :user, :current_user, :params

    def initialize(current_user, user, params = {})
      @user, @current_user, @params = user, current_user, params.dup
    end
  end
end
