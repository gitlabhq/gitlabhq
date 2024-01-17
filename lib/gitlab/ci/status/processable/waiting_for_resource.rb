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
              image: 'illustrations/empty-state/empty-job-pending-md.svg',
              size: '',
              title: _('This job is waiting for resource: ') + subject.resource_group.key
            }
          end

          def has_action?
            current_processable.present?
          end

          def action_icon
            nil
          end

          def action_title
            nil
          end

          def action_button_title
            _('View job currently using resource')
          end

          def action_path
            project_job_path(subject.project, current_processable)
          end

          def action_method
            :get
          end

          def self.matches?(processable, _)
            processable.waiting_for_resource?
          end

          private

          def current_processable
            @current_processable ||= subject.resource_group.current_processable
          end
        end
      end
    end
  end
end
