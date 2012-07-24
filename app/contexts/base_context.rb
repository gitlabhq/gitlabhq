class BaseContext
  attr_accessor :project, :current_user, :params

  def initialize(project, user, params)
    @project, @current_user, @params = project, user, params.dup
  end
end

