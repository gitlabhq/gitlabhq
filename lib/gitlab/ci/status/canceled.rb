module Gitlab
  module Ci
    module Status
      class Canceled < Status::Core
        def text
          s_('CiStatus|canceled')
        end

        def label
          s_('CiStatus|canceled')
        end

        def icon
          'icon_status_canceled'
        end

        def favicon
          'favicon_status_canceled'
        end
      end
    end
  end
end
