module Gitlab
  module Ci
    module Status
      class Manual < Status::Core
        def text
          'manual'
        end

        def label
          'manual action'
        end

        def icon
          'icon_status_manual'
        end

        def favicon
          'favicon_status_manual'
        end
      end
    end
  end
end
