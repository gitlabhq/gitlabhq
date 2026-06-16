# frozen_string_literal: true

module Authn
  class OauthApplicationPolicy < BasePolicy
    condition(:is_owner) { @subject.owner == @user }

    rule { is_owner }.enable :read_oauth_application
    rule { is_owner }.enable :update_oauth_application
    rule { is_owner }.enable :delete_oauth_application
  end
end
