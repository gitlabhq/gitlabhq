module Gitlab
  module Ci
    module Status
      class Manual < Status::Core
        def text
          s_('CiStatusText|manual')
        end

        def label
          s_('CiStatusLabel|manual action')
        end

        def icon
          'status_manual'
        end

        def favicon
          'favicon_status_manual'
        end
      end
    end
  end
end
