module Gitlab
  module Ci
    module Status
      module Build
        class ManualWithAutoPlay < Status::Extended
          ###
          # TODO: Those are random values. We have to fix accoding to the UX review
          ###

          ###
          # Core override
          ###
          def text
            s_('CiStatusText|scheduled')
          end

          def label
            s_('CiStatusLabel|scheduled')
          end

          def icon
            'timer'
          end

          def favicon
            'favicon_status_manual_with_auto_play'
          end

          ###
          # Extension override
          ###
          def illustration
            {
              image: 'illustrations/canceled-job_empty.svg',
              size: 'svg-394',
              title: _('This job is a scheduled job with manual actions!'),
              content: _('auto playyyyyyyyyyyyyy! This job depends on a user to trigger its process. Often they are used to deploy code to production environments')
            }
          end

          def status_tooltip
            @status.status_tooltip + " (scheulded) : Execute in #{subject.build_schedule.execute_in.round} sec"
          end

          def self.matches?(build, user)
            build.autoplay? && !build.canceled?
          end
        end
      end
    end
  end
end
