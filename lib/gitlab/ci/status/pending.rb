module Gitlab
  module Ci
    module Status
      class Pending < Status::Core
        def text
          s_('CiStatusText|pending')
        end

        def label
          s_('CiStatusLabel|pending')
        end

        def icon
          'status_pending'
        end

        def favicon
          'favicon_status_pending'
        end

        def illustration
          'pending_job_empty'
        end
      end
    end
  end
end
