class BaseService
  attr_accessor :project, :current_user, :params

  def initialize(project, user, params)
    @project, @current_user, @params = project, user, params.dup
  end

  def abilities
    @abilities ||= begin
                     abilities = Six.new
                     abilities << Ability
                     abilities
                   end
  end

  def can?(object, action, subject)
    abilities.allowed?(object, action, subject)
  end
end
