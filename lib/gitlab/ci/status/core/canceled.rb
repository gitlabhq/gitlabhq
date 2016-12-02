module Gitlab::Ci
  module Status
    module Core
      class Canceled < Core::Base
        def text
          'canceled'
        end

        def label
          'canceled'
        end

        def icon
          'icon_status_canceled'
        end
      end
    end
  end
end
