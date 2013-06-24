module Teams
  class BaseContext < ::BaseContext
    attr_accessor :team, :current_user, :params

    def initialize(user, team, params = {})
      @team, @current_user, @params = team, user, params.dup
    end
  end
end
