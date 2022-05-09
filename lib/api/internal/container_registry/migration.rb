# frozen_string_literal: true

module API
  module Internal
    module ContainerRegistry
      class Migration < ::API::Base
        feature_category :container_registry
        urgency :low

        STATUS_PRE_IMPORT_COMPLETE = 'pre_import_complete'
        STATUS_PRE_IMPORT_FAILED = 'pre_import_failed'
        STATUS_IMPORT_COMPLETE = 'import_complete'
        STATUS_IMPORT_FAILED = 'import_failed'
        POSSIBLE_VALUES = [
          STATUS_PRE_IMPORT_COMPLETE,
          STATUS_PRE_IMPORT_FAILED,
          STATUS_IMPORT_COMPLETE,
          STATUS_IMPORT_FAILED
        ].freeze

        before { authenticate! }

        helpers do
          def authenticate!
            secret_token = Gitlab.config.registry.notification_secret

            unauthorized! unless Devise.secure_compare(secret_token, headers['Authorization'])
          end

          def find_repository!(path)
            ::ContainerRepository.find_by_path!(::ContainerRegistry::Path.new(path))
          end
        end

        params do
          requires :repository_path, type: String, desc: 'The container repository path'
          requires :status, type: String, values: POSSIBLE_VALUES, desc: 'The migration step status'
        end
        put 'internal/registry/repositories/*repository_path/migration/status' do
          ::Gitlab::Database::LoadBalancing::Session.current.use_primary do
            repository = find_repository!(declared_params[:repository_path])

            unless repository.migration_in_active_state?
              bad_request!("Wrong migration state (#{repository.migration_state})")
            end

            case declared_params[:status]
            when STATUS_PRE_IMPORT_COMPLETE
              unless repository.finish_pre_import_and_start_import
                bad_request!("Couldn't transition from pre_importing to importing")
              end
            when STATUS_IMPORT_COMPLETE
              unless repository.finish_import
                bad_request!("Couldn't transition from importing to import_done")
              end
            when STATUS_IMPORT_FAILED, STATUS_PRE_IMPORT_FAILED
              repository.abort_import!
            end
          end

          status 200
        end
      end
    end
  end
end
