# frozen_string_literal: true

module Applications
  class CreateService
    attr_reader :current_user, :request, :params

    # EE would override and use `request` arg
    def initialize(current_user, request, params)
      @current_user = current_user
      @request = request
      @params = params.except(:ip_address)
    end

    def execute
      @application = Authn::OauthApplication.new(params)

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
