class BaseContext
  attr_accessor :current_user, :params

  def initialize(user, params)
    @current_user, @params = user, params.dup
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
