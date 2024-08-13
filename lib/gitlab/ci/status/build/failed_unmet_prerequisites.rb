# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class FailedUnmetPrerequisites < Status::Extended
          def illustration
            {
              image: 'illustrations/empty-state/empty-job-failed-md.svg',
              size: '',
              title: _('Failed to create resources'),
              content: _('Run this job again in order to create the necessary resources.')
            }
          end

          def self.matches?(build, _)
            build.unmet_prerequisites?
          end
        end
      end
    end
  end
end
