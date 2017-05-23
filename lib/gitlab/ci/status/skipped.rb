module Gitlab
  module Ci
    module Status
      class Skipped < Status::Core
        def text
          s_('CiStatus|skipped')
        end

        def label
          s_('CiStatus|skipped')
        end

        def icon
          'icon_status_skipped'
        end

        def favicon
          'favicon_status_skipped'
        end
      end
    end
  end
end
