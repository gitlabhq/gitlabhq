module Gitlab
  module Ci
    module Status
      class Scheduled < Status::Core
        def text
          s_('CiStatusText|scheduled')
        end

        def label
          s_('CiStatusLabel|scheduled')
        end

        def icon
          'status_scheduled'
        end

        def favicon
          'favicon_status_scheduled'
        end
      end
    end
  end
end
