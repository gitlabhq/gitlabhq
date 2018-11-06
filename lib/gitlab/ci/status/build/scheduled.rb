# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Scheduled < Status::Extended
          def illustration
            {
              image: 'illustrations/illustrations_scheduled-job_countdown.svg',
              size: 'svg-394',
              title: _("This is a delayed to run in ") + " #{execute_in}",
              content: _("This job will automatically run after it's timer finishes. " \
                         "Often they are used for incremental roll-out deploys " \
                         "to production environments. When unscheduled it converts " \
                         "into a manual action.")
            }
          end

          def status_tooltip
            "delayed manual action (#{execute_in})"
          end

          def self.matches?(build, user)
            build.scheduled? && build.scheduled_at
          end

          private

          include TimeHelper

          def execute_in
            remaining_seconds = [0, subject.scheduled_at - Time.now].max
            duration_in_numbers(remaining_seconds)
          end
        end
      end
    end
  end
end
