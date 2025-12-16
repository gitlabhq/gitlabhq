# frozen_string_literal: true

module Groups
  class SavedViewsController < Groups::ApplicationController
    before_action :authenticate_user!

    feature_category :portfolio_management

    def subscribe
      not_found
    end
  end
end
