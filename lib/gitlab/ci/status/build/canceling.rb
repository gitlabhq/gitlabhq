# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Canceling < Status::Extended
          def illustration
            {
              image: 'illustrations/canceled-job_empty.svg',
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
