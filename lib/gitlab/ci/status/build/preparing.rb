# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Preparing < Status::Extended
          ##
          # TODO: image is shared with 'pending'
          # until we get a dedicated one
          #
          def illustration
            {
              image: 'illustrations/empty-state/empty-job-not-triggered-md.svg',
              size: '',
              title: _('This job is preparing to start'),
              content: _('This job is performing tasks that must complete before it can start')
            }
          end

          def self.matches?(build, _)
            build.preparing?
          end
        end
      end
    end
  end
end
