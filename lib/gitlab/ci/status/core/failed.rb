module Gitlab::Ci
  module Status
    module Core
      class Failed < Core::Base
        def label
          'failed'
        end

        def icon
          'icon_status_failed'
        end
      end
    end
  end
end
