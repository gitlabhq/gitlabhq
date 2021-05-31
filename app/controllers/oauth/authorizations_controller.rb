# frozen_string_literal: true

class Oauth::AuthorizationsController < Doorkeeper::AuthorizationsController
  include Gitlab::Experimentation::ControllerConcern
  include InitializesCurrentUserMode

  before_action :verify_confirmed_email!, :verify_confidential_application!

  layout 'profile'

  # Overridden from Doorkeeper::AuthorizationsController to
  # include the call to session.delete
  def new
    if pre_auth.authorizable?
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
