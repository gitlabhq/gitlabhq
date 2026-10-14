# frozen_string_literal: true

module Applications
  class CreateService
    InsideTransactionError = Class.new(StandardError)

    attr_reader :current_user, :request, :params

    # The DeclareService response, nil when params carried no granular_scopes
    attr_reader :declaration

    # EE would override and use `request` arg
    def initialize(current_user, request, params, access_token: nil)
      @current_user = current_user
      @request = request
      @params = params.except(:ip_address, :granular_scopes)
      @granular_scope_inputs = params[:granular_scopes]
      @access_token = access_token
    end

    def execute
      @application = Authn::OauthApplication.new(params)

      unless params[:scopes].present?
        @application.errors.add(:base, _("Scopes can't be blank"))

        return @application
      end

      # A joined transaction would swallow the ActiveRecord::Rollback that undoes a refused set
      raise InsideTransactionError if granular_scope_inputs && ::ApplicationRecord.inside_transaction?

      # One transaction so that a refused scope set leaves no application behind
      Authn::OauthApplication.transaction do
        next unless @application.save
        next if granular_scope_inputs.nil?

        @declaration = declare_granular_scopes
        next unless @declaration.error?

        @application.errors.add(:base, @declaration.message)
        raise ActiveRecord::Rollback
      end

      @application
    end

    private

    attr_reader :granular_scope_inputs, :access_token

    def declare_granular_scopes
      ::Authz::OauthApplicationGranularScopes::DeclareService.new(
        current_user: current_user, application: @application, inputs: granular_scope_inputs,
        access_token: access_token
      ).execute
    end
  end
end

Applications::CreateService.prepend_mod_with('Applications::CreateService')
