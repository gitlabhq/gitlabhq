# frozen_string_literal: true

module Admin
  module Organizations
    class DashboardController < Admin::Organizations::ApplicationController
      feature_category :organization
    end
  end
end
