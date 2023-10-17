# frozen_string_literal: true

class Oauth::TokensController < Doorkeeper::TokensController
  include EnforcesTwoFactorAuthentication
  include RequestPayloadLogger

  alias_method :auth_user, :current_user
end
