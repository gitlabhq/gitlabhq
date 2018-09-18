module Gitlab
  module Ci
    module Status
      module Build
        class Scheduled < Status::Extended
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
            'favicon_status_scheduled'
          end

          ###
          # Extension override
          ###
          def illustration
            {
              image: 'illustrations/canceled-job_empty.svg',
              size: 'svg-394',
              title: _("This is a scheduled to run in ") + " #{execute_in}",
              content: _("This job will automatically run after it's timer finishes. Often they are used for incremental roll-out deploys to production environments. When unscheduled it converts into a manual action.")
            }
          end

          def status_tooltip
            "scheduled manual action (#{execute_in})"
          end

          def self.matches?(build, user)
            build.schedulable? && !build.canceled?
          end

          private

          def execute_in
            Time.at(subject.build_schedule.execute_in).utc.strftime("%H:%M:%S")
          end
        end
      end
    end
  end
end
