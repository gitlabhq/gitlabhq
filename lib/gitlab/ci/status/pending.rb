module Gitlab
  module Ci
    module Status
      class Pending < Status::Core
        def text
          s_('CiStatus|pending')
        end

        def label
          s_('CiStatus|pending')
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
