module Gitlab
  module Ci
    module Status
      class Running < Status::Core
        def text
          s_('CiStatus|running')
        end

        def label
          s_('CiStatus|running')
        end

        def icon
          'status_running'
        end

        def favicon
          'favicon_status_running'
        end
      end
    end
  end
end
