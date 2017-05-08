module Gitlab
  module Ci
    module Status
      class Pending < Status::Core
        def text
          _('pending')
        end

        def label
          _('pending')
        end

        def icon
          'icon_status_pending'
        end

        def favicon
          'favicon_status_pending'
        end
      end
    end
  end
end
