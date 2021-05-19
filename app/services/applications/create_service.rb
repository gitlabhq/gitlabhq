# frozen_string_literal: true

module Applications
  class CreateService
    attr_reader :current_user, :params

    def initialize(current_user, params)
      @current_user = current_user
      @params = params.except(:ip_address)
    end

    # EE would override and use `request` arg
    def execute(request)
      @application = Doorkeeper::Application.new(params)

      unless params[:scopes].present?
        @application.errors.add(:base, _("Scopes can't be blank"))

        return @application
      end

      @application.save
      @application
    end
  end
end

Applications::CreateService.prepend_mod_with('Applications::CreateService')
