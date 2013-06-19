module Projects
  class BaseContext < ::BaseContext
    attr_accessor :project, :current_user, :params

    def initialize(user, project, params = {})
      @project, @current_user, @params = project, user, params.dup
    end
  end
end
