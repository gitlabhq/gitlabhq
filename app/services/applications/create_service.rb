module Applications
  class CreateService
    def initialize(current_user, params)
      @current_user = current_user
      @params = params
      @ip_address = @params.delete(:ip_address)
    end

    def execute(request = nil)
      Doorkeeper::Application.create(@params)
    end
  end
end
