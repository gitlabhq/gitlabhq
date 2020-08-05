# frozen_string_literal: true

class Oauth::TokensController < Doorkeeper::TokensController
  include EnforcesTwoFactorAuthentication
end
