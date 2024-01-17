# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Canceled < Status::Extended
          def illustration
            {
              image: 'illustrations/empty-state/empty-job-canceled-md.svg',
              size: '',
              title: _('This job has been canceled')
            }
          end

          def self.matches?(build, user)
            build.canceled?
          end
        end
      end
    end
  end
end
