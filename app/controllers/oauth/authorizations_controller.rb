# frozen_string_literal: true

class Oauth::AuthorizationsController < Doorkeeper::AuthorizationsController
  include Gitlab::Experimentation::ControllerConcern
  include InitializesCurrentUserMode
  include Gitlab::Utils::StrongMemoize

  before_action :verify_confirmed_email!, :verify_confidential_application!

  layout 'profile'

  # Overridden from Doorkeeper::AuthorizationsController to
  # include the call to session.delete
  def new
    logger.info("#{self.class.name}#new: pre_auth_params['scope'] = #{pre_auth_params['scope'].inspect}")

    if pre_auth.authorizable?
      logger.info("#{self.class.name}#new: pre_auth.scopes = #{pre_auth.scopes.to_a.inspect}")
      if skip_authorization? || matching_token?
        auth = authorization.authorize
        parsed_redirect_uri = URI.parse(auth.redirect_uri)
        session.delete(:user_return_to)
        render "doorkeeper/authorizations/redirect", locals: { redirect_uri: parsed_redirect_uri }, layout: false
      else
        render "doorkeeper/authorizations/new"
      end
    else
      render "doorkeeper/authorizations/error"
    end
  end

  private

  def pre_auth_params
    # Cannot be achieved with a before_action hook, due to the execution order.
    downgrade_scopes! if action_name == 'new'

    super
  end

  # limit scopes when signing in with GitLab
  def downgrade_scopes!
    return unless Feature.enabled?(:omniauth_login_minimal_scopes, current_user,
                                   default_enabled: :yaml)

    auth_type = params.delete('gl_auth_type')
    return unless auth_type == 'login'

    logger.info("#{self.class.name}: BEFORE application has read_user: #{application_has_read_user_scope?}")
    logger.info("#{self.class.name}: BEFORE scope = #{params['scope'].inspect}")

    ensure_read_user_scope!

    params['scope'] = Gitlab::Auth::READ_USER_SCOPE.to_s if application_has_read_user_scope?

    logger.info("#{self.class.name}: AFTER application has read_user: #{application_has_read_user_scope?}")
    logger.info("#{self.class.name}: AFTER scope = #{params['scope'].inspect}")
  end

  # Configure the application to support read_user scope, if it already
  # supports scopes with greater levels of privileges.
  def ensure_read_user_scope!
    return if application_has_read_user_scope?
    return unless application_has_api_scope?

    add_read_user_scope!
  end

  def add_read_user_scope!
    return unless doorkeeper_application

    scopes = doorkeeper_application.scopes
    scopes.add(Gitlab::Auth::READ_USER_SCOPE)
    doorkeeper_application.scopes = scopes
    doorkeeper_application.save!
  end

  def doorkeeper_application
    strong_memoize(:doorkeeper_application) { ::Doorkeeper::OAuth::Client.find(params['client_id'])&.application }
  end

  def application_has_read_user_scope?
    doorkeeper_application&.includes_scope?(Gitlab::Auth::READ_USER_SCOPE)
  end

  def application_has_api_scope?
    doorkeeper_application&.includes_scope?(*::Gitlab::Auth::API_SCOPES)
  end

  # Confidential apps require the client_secret to be sent with the request.
  # Doorkeeper allows implicit grant flow requests (response_type=token) to
  # work without client_secret regardless of the confidential setting.
  # This leads to security vulnerabilities and we want to block it.
  def verify_confidential_application!
    render 'doorkeeper/authorizations/error' if authorizable_confidential?
  end

  def authorizable_confidential?
    pre_auth.authorizable? && pre_auth.response_type == 'token' && pre_auth.client.application.confidential
  end

  def verify_confirmed_email!
    return if current_user&.confirmed?

    pre_auth.error = :unconfirmed_email
    render "doorkeeper/authorizations/error"
  end
end
