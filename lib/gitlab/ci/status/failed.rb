module Gitlab
  module Ci
    module Status
      class Failed < Status::Core
        def text
          _('failed')
        end

        def label
          _('failed')
        end

        def icon
          'icon_status_failed'
        end

        def favicon
          'favicon_status_failed'
        end
      end
    end
  end
end
