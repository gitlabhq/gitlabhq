# frozen_string_literal: true

# This is a base controller for doorkeeper.
# It adds the `can?` helper used in the views.
module Gitlab
  # rubocop:disable Rails/ApplicationController
  class BaseDoorkeeperController < ActionController::Base
    include Gitlab::Allowable
    include EnforcesTwoFactorAuthentication
    include SessionsHelper

    before_action :limit_session_time, if: -> { !current_user }

    helper_method :can?
  end
  # rubocop:enable Rails/ApplicationController
end
