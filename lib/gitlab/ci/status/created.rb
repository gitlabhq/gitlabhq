module Gitlab
  module Ci
    module Status
      class Created < Status::Core
        def text
          s_('CiStatusText|created')
        end

        def label
          s_('CiStatusLabel|created')
        end

        def icon
          'status_created'
        end

        def favicon
          'favicon_status_created'
        end

        def illustration
          {
            image: 'illustrations/job_not_triggered.svg',
            size: 'svg-306',
            title: _('This job has not been triggered yet'),
            content: _('This job depends on upstream jobs that need to succeed in order for this job to be triggered')
          }
        end
      end
    end
  end
end
