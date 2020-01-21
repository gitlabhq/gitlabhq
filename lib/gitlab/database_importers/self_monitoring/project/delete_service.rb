# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module SelfMonitoring
      module Project
        class DeleteService < ::BaseService
          include Stepable
          include SelfMonitoring::Helpers

          steps :validate_self_monitoring_project_exists,
            :destroy_project

          def initialize
            super(nil)
          end

          def execute
            execute_steps
          end

          private

          def validate_self_monitoring_project_exists(result)
            unless project_created? || self_monitoring_project_id.present?
              return error(_('Self monitoring project does not exist'))
            end

            success(result)
          end

          def destroy_project(result)
            return success(result) unless project_created?

            if self_monitoring_project.destroy
              success(result)
            else
              log_error(self_monitoring_project.errors.full_messages)
              error(_('Error deleting project. Check logs for error details.'))
            end
          end
        end
      end
    end
  end
end
