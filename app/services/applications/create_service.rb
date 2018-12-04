# frozen_string_literal: true

module Applications
  class CreateService
    # rubocop: disable CodeReuse/ActiveRecord
    def initialize(current_user, params)
      @current_user = current_user
      @params = params.except(:ip_address)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # EE would override and use `request` arg
    def execute(request)
      Doorkeeper::Application.create(@params)
    end
  end
end
