module Gitlab
  module Ci
    module Status
      class Success < Status::Core
        def text
          s_('CiStatus|passed')
        end

        def label
          s_('CiStatus|passed')
        end

        def icon
          'icon_status_success'
        end

        def favicon
          'favicon_status_success'
        end
      end
    end
  end
end
