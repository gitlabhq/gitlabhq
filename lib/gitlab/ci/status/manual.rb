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

        def illustration
          {
            image: 'illustrations/manual_action.svg',
            size: 'svg-394',
            title: _('This job requires a manual action'),
            content: _('This job depends on a user to trigger its process. Often they are used to deploy code to production environments')
          }
        end
      end
    end
  end
end
