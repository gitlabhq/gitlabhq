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
          {
            image: 'illustrations/pending_job_empty.svg',
            size: 'svg-430',
            title: _('This job has not started yet'),
            content: _('This job is in pending state and is waiting to be picked by a runner')
          }
        end
      end
    end
  end
end
