# frozen_string_literal: true

# Central point for managing default attributes from within
# the metrics dashboard module.
module Gitlab
  module Metrics
    module Dashboard
      module Defaults
        DEFAULT_PANEL_TYPE = 'area-chart'
        DEFAULT_PANEL_WEIGHT = 0
      end
    end
  end
end
