module Gitlab::Ci
  module Status
    module Core
      class Pending < Core::Base
        def label
          'pending'
        end

        def icon
          'icon_status_pending'
        end
      end
    end
  end
end
