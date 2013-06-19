module Teams
  module Users
    class BaseContext < Teams::BaseContext
      attr_accessor :team, :user, :current_user, :params

      def initialize(actor, team, user, params = {})
        @current_user, @team, @user, @params = actor, team, user, params.dup
      end
    end
  end
end
