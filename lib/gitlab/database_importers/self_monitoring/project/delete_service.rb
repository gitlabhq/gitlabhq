# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module SelfMonitoring
      module Project
        class DeleteService < ::BaseService
          include Stepable
          include SelfMonitoring::Helpers

          steps :validate_self_monitoring_project_exists,
            :destroy_project_owner,
            :delete_project_id

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

          def destroy_project_owner(result)
            return success(result) unless project_created?

            if self_monitoring_project.owner.destroy
              success(result)
            else
              log_error(self_monitoring_project.errors.full_messages)
              error(_('Error deleting project. Check logs for error details.'))
            end
          end

          def delete_project_id(result)
            update_result = application_settings.update(
              instance_administration_project_id: nil
            )

            if update_result
              success(result)
            else
              log_error("Could not delete self monitoring project ID, errors: %{errors}" % { errors: application_settings.errors.full_messages })
              error(_('Could not delete project ID'))
            end
          end
        end
      end
    end
  end
end
