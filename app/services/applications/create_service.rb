module Applications
  class CreateService
    prepend ::EE::Applications::CreateService

    def initialize(current_user, params)
      @current_user = current_user
      @params = params.except(:ip_address)
    end

    def execute(request = nil)
      Doorkeeper::Application.create(@params)
    end
  end
end
