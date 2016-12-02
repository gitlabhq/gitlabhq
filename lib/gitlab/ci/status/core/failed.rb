module Gitlab::Ci
  module Status
    module Core
      class Failed < Core::Base
        def text
          'failed'
        end

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
