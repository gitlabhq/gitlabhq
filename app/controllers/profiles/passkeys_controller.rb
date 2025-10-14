# frozen_string_literal: true

module Profiles
  class PasskeysController < Profiles::ApplicationController
    before_action :check_passkeys_available!

    feature_category :system_access

    def new
      # TODO: Add any needed controller code
      render :new
    end

    def create
      # TODO: Add any needed controller code
    end

    def destroy
      # TODO: Add any needed controller code
    end

    private

    def check_passkeys_available!
      render_404 unless Feature.enabled?(:passkeys, current_user)
    end
  end
end
