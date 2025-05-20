# frozen_string_literal: true

module Organizations
  class SettingsController < ApplicationController
    feature_category :organization

    before_action :authorize_admin_organization!

    def general; end
  end
end
