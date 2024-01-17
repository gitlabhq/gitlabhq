# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Skipped < Status::Extended
          def illustration
            {
              image: 'illustrations/empty-state/empty-job-skipped-md.svg',
              size: '',
              title: _('This job has been skipped')
            }
          end

          def self.matches?(build, user)
            build.skipped?
          end
        end
      end
    end
  end
end
