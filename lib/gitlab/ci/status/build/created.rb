# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Created < Status::Extended
          def illustration
            {
              image: 'illustrations/empty-state/empty-job-not-triggered-md.svg',
              size: '',
              title: _('This job has not been triggered yet'),
              content: _('This job depends on upstream jobs that need to succeed in order for this job to be triggered')
            }
          end

          def self.matches?(build, user)
            build.created?
          end
        end
      end
    end
  end
end
