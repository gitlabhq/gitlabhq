module Gitlab
  module Ci
    module Status
      class Running < Status::Core
        def text
          'running'
        end

        def label
          'running'
        end

        def icon
          'icon_status_running'
        end

        def favicon
          'favicon_status_running'
        end
      end
    end
  end
end
