# frozen_string_literal: true

module Gitlab
  module Instrumentation
    module Gvl
      class << self
        def toggle(enabled)
          if enabled
            GVLTools::LocalTimer.enable
            GVLTools::GlobalTimer.enable
          else
            GVLTools::LocalTimer.disable
            GVLTools::GlobalTimer.disable
          end
        end
      end
    end
  end
end
