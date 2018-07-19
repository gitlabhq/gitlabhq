# frozen_string_literal: true

module Applications
  class CreateService
    def initialize(current_user, params)
      @current_user = current_user
      @params = params.except(:ip_address)
    end

    def execute(request)
      Doorkeeper::Application.create(@params)
    end
  end
end
