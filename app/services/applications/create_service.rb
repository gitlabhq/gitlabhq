# frozen_string_literal: true

module Applications
  class CreateService
    attr_reader :current_user, :params

    ## Overridden in EE
    def self.disable_ropc_available?
      false
    end

    def initialize(current_user, params)
      @current_user = current_user
      @params = params.except(:ip_address)
    end

    # EE would override and use `request` arg
    def execute(request)
      @application = Authn::OauthApplication.new(params)

      unless params[:scopes].present?
        @application.errors.add(:base, _("Scopes can't be blank"))

        return @application
      end

      @application.ropc_enabled = false if self.class.disable_ropc_available?
      @application.save
      @application
    end
  end
end

Applications::CreateService.prepend_mod_with('Applications::CreateService')
