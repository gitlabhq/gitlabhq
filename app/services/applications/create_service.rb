# frozen_string_literal: true

module Applications
  class CreateService
<<<<<<< HEAD
    prepend ::EE::Applications::CreateService

=======
>>>>>>> upstream/master
    # rubocop: disable CodeReuse/ActiveRecord
    def initialize(current_user, params)
      @current_user = current_user
      @params = params.except(:ip_address)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def execute(request)
      Doorkeeper::Application.create(@params)
    end
  end
end
