module Gitlab
  module Ci
    module Status
      class Canceled < Status::Core
        def text
          s_('CiStatusText|canceled')
        end

        def label
          s_('CiStatusLabel|canceled')
        end

        def icon
          'status_canceled'
        end

        def favicon
          'favicon_status_canceled'
        end

        def illustration
          {
            image: 'illustrations/canceled-job_empty.svg',
            size: 'svg-430',
            title: _('This job has been canceled')
          }
        end
      end
    end
  end
end
