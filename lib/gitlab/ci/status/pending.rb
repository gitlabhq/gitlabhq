module Gitlab
  module Ci
    module Status
      class Pending < Status::Core
        def text
          'pending'
        end

        def label
          'pending'
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
