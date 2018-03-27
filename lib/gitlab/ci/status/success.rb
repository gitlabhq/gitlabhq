module Gitlab
  module Ci
    module Status
      class Success < Status::Core
        def text
          s_('CiStatusText|passed')
        end

        def label
          s_('CiStatusLabel|passed')
        end

        def icon
          'status_success'
        end

        def favicon
          'favicon_status_success'
        end
      end
    end
  end
end
