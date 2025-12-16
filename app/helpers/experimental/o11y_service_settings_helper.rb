# frozen_string_literal: true

module Experimental
  module O11yServiceSettingsHelper
    def o11y_per_page_options
      [10, 20, 50, Experimental::O11yServiceSettingsController::MAX_PER_PAGE]
    end
  end
end
