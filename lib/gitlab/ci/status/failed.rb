module Gitlab
  module Ci
    module Status
      class Failed < Status::Core
        def text
          s_('CiStatus|failed')
        end

        def label
          s_('CiStatus|failed')
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
