# frozen_string_literal: true

# This is a base controller for doorkeeper.
# It adds the `can?` helper used in the views.
module Gitlab
  class BaseDoorkeeperController < BaseActionController
    include Gitlab::Allowable
    include EnforcesTwoFactorAuthentication
    include SessionsHelper

    helper_method :can?
  end
end
