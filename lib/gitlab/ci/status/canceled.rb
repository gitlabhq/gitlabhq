module Gitlab
  module Ci
    module Status
      class Canceled < Status::Core
        def text
          s_('CiStatusText|canceled')
        end

        def label
          s_('CiStatusLabel|canceled')
        end

        def icon
          'status_canceled'
        end

        def favicon
          'favicon_status_canceled'
        end
      end
    end
  end
end
