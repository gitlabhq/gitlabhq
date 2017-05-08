module Gitlab
  module Ci
    module Status
      class Canceled < Status::Core
        def text
          _('canceled')
        end

        def label
          _('canceled')
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
