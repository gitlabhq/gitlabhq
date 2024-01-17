# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Pending < Status::Extended
          def illustration
            {
              image: 'illustrations/empty-state/empty-job-pending-md.svg',
              size: '',
              title: _('This job has not started yet'),
              content: _('This job is in pending state and is waiting to be picked by a runner')
            }
          end

          def self.matches?(build, user)
            build.pending?
          end
        end
      end
    end
  end
end
