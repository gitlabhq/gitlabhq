# frozen_string_literal: true

# This is a base controller for doorkeeper.
# It adds the `can?` helper used in the views.
module Gitlab
  class BaseDoorkeeperController < ActionController::Base
    include Gitlab::Allowable
    include EnforcesTwoFactorAuthentication

    helper_method :can?
  end
end
