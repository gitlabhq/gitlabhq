# frozen_string_literal: true

module Admin
  module O11yServiceSettingsHelper
    def o11y_per_page_options
      [10, 20, 50, Admin::O11yServiceSettingsController::MAX_PER_PAGE]
    end
  end
end
