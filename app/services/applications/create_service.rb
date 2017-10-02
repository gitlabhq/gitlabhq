module Applications
  class CreateService
    prepend ::EE::Applications::CreateService

    def initialize(current_user, params)
      @current_user = current_user
      @params = params
    end

    def execute
      Doorkeeper::Application.create(@params)
    end
  end
end
