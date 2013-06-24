module Teams
  module Projects
    class BaseContext < Teams::BaseContext
      attr_accessor :team, :project, :current_user, :params

      def initialize(user, team, project, params = {})
        @current_user, @project, @team, @params = user, project, team, params.dup
      end
    end
  end
end
