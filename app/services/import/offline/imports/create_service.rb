# frozen_string_literal: true

module Import
  module Offline
    module Imports
      class CreateService
        # @param storage_configuration [Hash]
        #   {
        #     bucket: 'my-bucket',
        #     provider: 'aws',
        #     export_prefix: 'my-export',
        #     object_storage_credentials: {
        #       aws_access_key_id: 'AwsUserAccessKey',
        #       aws_secret_access_key: 'aws/secret+access/key',
        #       region: 'us-east-1',
        #       path_style: false
        #     }
        #   }
        # @option params [entities] An array of entity paths to import. This may be
        #   a subset of the entities defined in the export's metadata.json.
        def initialize(storage_configuration, params, current_user:, fallback_organization:)
          @params = params
          @storage_configuration = storage_configuration
          @current_user = current_user
          @fallback_organization = fallback_organization
        end

        def execute
          return feature_flag_disabled_error unless Feature.enabled?(:offline_transfer_imports, current_user)
          return destination_validation_error unless destinations_valid?

          bulk_import = BulkImport.transaction do
            create_bulk_import.tap do |bulk_import|
              create_offline_transfer_config(bulk_import)
            end
          end

          ScheduleImportWorker.perform_async(bulk_import.id, Array.wrap(params[:entities]).map(&:deep_stringify_keys))

          ServiceResponse.success(payload: bulk_import)
        end

        private

        attr_reader :current_user, :storage_configuration, :params, :fallback_organization

        def create_bulk_import
          BulkImport.create!(
            user: current_user,
            source_type: 'offline_export',
            source_enterprise: false,
            organization: organization(params.dig(:entities, 0, :destination_namespace))
          )
        end

        def create_offline_transfer_config(bulk_import)
          bulk_import.create_offline_configuration!(
            storage_configuration.merge(organization: bulk_import.organization)
          )
        end

        def destinations_valid?
          Array.wrap(params[:entities]).each do |entity_params|
            destination_validator.validate!(
              entity_params[:destination_namespace],
              entity_params[:destination_slug],
              entity_params[:destination_name],
              entity_params[:source_type]
            )
          end

          true
        rescue ::BulkImports::Error
          false
        end

        def destination_validator
          @destination_validator ||= ::Import::Framework::DestinationValidator.new(current_user: current_user)
        end

        def destination_validation_error
          service_error(s_('OfflineTransfer|One or more destination paths is invalid.'))
        end

        def feature_flag_disabled_error
          service_error('offline_transfer_imports feature flag must be enabled.')
        end

        def service_error(message)
          ServiceResponse.error(
            message: message,
            reason: :unprocessable_entity
          )
        end

        def organization(namespace = nil)
          Group.find_by_full_path(namespace)&.organization || fallback_organization
        end
      end
    end
  end
end
