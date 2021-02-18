# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Processable
        class WaitingForResource < Status::Extended
          ##
          # TODO: image is shared with 'pending'
          # until we get a dedicated one
          #
          def illustration
            {
              image: 'illustrations/pending_job_empty.svg',
              size: 'svg-430',
              title: _('This job is waiting for resource: ') + subject.resource_group.key
            }
          end

          def self.matches?(processable, _)
            processable.waiting_for_resource?
          end
        end
      end
    end
  end
end
