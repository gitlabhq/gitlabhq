# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Canceling < Status::Extended
          def illustration
            {
              image: 'illustrations/empty-state/empty-job-canceled-md.svg',
              size: '',
              title: _('This job is in the process of canceling')
            }
          end

          def self.matches?(build, _user)
            build.canceling?
          end
        end
      end
    end
  end
end
