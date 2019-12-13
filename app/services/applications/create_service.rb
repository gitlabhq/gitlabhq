# frozen_string_literal: true

module Applications
  class CreateService
    attr_reader :current_user, :params

    def initialize(current_user, params)
      @current_user = current_user
      @params = params.except(:ip_address) # rubocop: disable CodeReuse/ActiveRecord
    end

    # EE would override and use `request` arg
    def execute(request)
      Doorkeeper::Application.create(params)
    end
  end
end

Applications::CreateService.prepend(EE::Applications::CreateService)
