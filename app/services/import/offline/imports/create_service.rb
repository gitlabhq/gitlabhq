# frozen_string_literal: true

module Import
  module Offline
    module Imports
      class CreateService
        include Gitlab::Utils::StrongMemoize

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
        # @option params [import_all] A hash with a single destination_namespace, to
        #   import every top-level group in the export. Mutually exclusive with entities.
        def initialize(storage_configuration, params, current_user:, fallback_organization:)
          @params = params
          @storage_configuration = storage_configuration
          @current_user = current_user
          @fallback_organization = fallback_organization
        end

        def execute
          return adc_admin_required_error if adc_without_admin?
          return destination_validation_error unless destinations_valid?
          return cross_organization_error(cross_organization_destination) if cross_organization_destination

          bulk_import = BulkImport.transaction do
            create_bulk_import.tap do |bulk_import|
              create_offline_transfer_config(bulk_import)
            end
          end

          ScheduleImportWorker.perform_async(
            bulk_import.id,
            Array.wrap(params[:entities]).map(&:deep_stringify_keys),
            import_all_params&.deep_stringify_keys
          )

          ServiceResponse.success(payload: bulk_import)
        rescue ActiveRecord::RecordInvalid => e
          service_error(e.message)
        end

        private

        attr_reader :current_user, :storage_configuration, :params, :fallback_organization

        def create_bulk_import
          BulkImport.create!(
            user: current_user,
            source_type: 'offline_export',
            source_enterprise: false,
            organization: organization(destination_namespaces.first)
          )
        end

        def create_offline_transfer_config(bulk_import)
          bulk_import.create_offline_configuration!(
            storage_configuration.merge(organization: bulk_import.organization)
          )
        end

        # For import_all only the destination namespace can be checked here. The
        # entity slugs are derived from the export's metadata.json, which is not read
        # until ScheduleImportService runs.
        def destinations_valid?
          if import_all_params
            destination_validator.validate_destination_namespace!(
              import_all_params[:destination_namespace],
              ::BulkImports::Entity::GROUP_ENTITY_SOURCE_TYPE
            )
          else
            Array.wrap(params[:entities]).each do |entity_params|
              destination_validator.validate!(
                entity_params[:destination_namespace],
                entity_params[:destination_slug],
                entity_params[:destination_name],
                entity_params[:source_type]
              )
            end
          end

          true
        rescue ::BulkImports::Error
          false
        end

        def import_all_params
          params[:import_all]
        end

        def destination_namespaces
          return [import_all_params[:destination_namespace]] if import_all_params

          # rubocop:disable Rails/Pluck -- pluck triggers Database/AvoidUsingPluckWithoutLimit, and these are param hashes, not records
          Array.wrap(params[:entities]).map { |entity_params| entity_params[:destination_namespace] }
          # rubocop:enable Rails/Pluck
        end
        strong_memoize_attr :destination_namespaces

        def destination_validator
          @destination_validator ||= ::Import::Framework::DestinationValidator.new(current_user: current_user)
        end

        def destination_validation_error
          service_error(s_('OfflineTransfer|One or more destination paths is invalid.'))
        end

        # Mirrors BulkImports::CreateService#validate_destination_organizations!.
        def cross_organization_destination
          groups_by_path = Group.where_full_path_in(destination_namespaces.compact_blank)
            .includes(:organization) # rubocop:disable CodeReuse/ActiveRecord -- eager-load org to avoid N+1 when resolving destinations
            .index_by { |group| group.full_path.downcase }

          destination_namespaces.each do |destination_namespace|
            destination_group = groups_by_path[destination_namespace&.downcase]
            resolved_organization = destination_group&.organization || fallback_organization

            next if resolved_organization == fallback_organization
            next unless resolved_organization.isolated? || fallback_organization.isolated?

            return destination_namespace
          end

          nil
        end
        strong_memoize_attr :cross_organization_destination

        def cross_organization_error(destination_namespace)
          service_error(::BulkImports::Error.cross_organization_destination(destination_namespace).message)
        end

        def adc_without_admin?
          uses_application_default_credentials? && !current_user.can_admin_all_resources?
        end

        def uses_application_default_credentials?
          Import::Offline::Configuration.new(provider: storage_configuration[:provider]).gcs_application_default?
        end

        def adc_admin_required_error
          service_error(s_('OfflineTransfer|Only administrators can use Application Default Credentials ' \
            'for offline transfer.'))
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
