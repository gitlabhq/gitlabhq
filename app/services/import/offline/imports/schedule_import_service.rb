# frozen_string_literal: true

module Import
  module Offline
    module Imports
      class ScheduleImportService
        include Gitlab::Utils::StrongMemoize

        ValidationError = Class.new(StandardError)

        # @param [BulkImport] bulk_import
        # @param [Array<Hash>] entities
        def initialize(bulk_import, entities)
          @bulk_import = bulk_import
          @entities = entities.map(&:deep_symbolize_keys)
        end

        def execute
          update_bulk_import
          create_entities(bulk_import)

          ::Import::BulkImports::EphemeralData.new(bulk_import.id).enable_importer_user_mapping
          BulkImportWorker.perform_async(bulk_import.id)

          ServiceResponse.success
        rescue ValidationError, MetadataFileReader::MetadataParseError, MetadataFileReader::UnsupportedVersionError => e
          logger.error(message: e.message, bulk_import_id: bulk_import.id)
          bulk_import.fail_op!
          ServiceResponse.error(message: e.message)
        end

        private

        attr_reader :bulk_import, :entities

        def update_bulk_import
          bulk_import.update!(
            source_version: metadata[:instance_version],
            source_enterprise: metadata[:instance_enterprise]
          )

          configuration.update!(entity_prefix_mapping: metadata[:entities_mapping])
        end

        def create_entities(bulk_import)
          ::BulkImports::Entity.by_bulk_import_id(bulk_import.id).delete_all

          Array.wrap(entities).each do |entity_params|
            track_access_level(entity_params)

            validate_entity_mapping!(entity_params[:source_full_path])

            ::BulkImports::Entity.create!(
              bulk_import: bulk_import,
              organization: bulk_import.organization,
              source_type: entity_params[:source_type],
              source_full_path: entity_params[:source_full_path],
              destination_slug: entity_params[:destination_slug],
              destination_namespace: entity_params[:destination_namespace]
            )
          end
        end

        def track_access_level(entity_params)
          ::Import::Framework::UserRoleTracker
            .new(
              current_user: bulk_import.user,
              tracking_class_name: self.class.name,
              import_type: 'offline_import_group'
            )
            .track(entity_params[:destination_namespace])
        end

        def validate_entity_mapping!(source_full_path)
          storage_key = metadata[:entities_mapping][source_full_path]
          raise ValidationError, "Metadata contains no mapping for entity path '#{source_full_path}'" unless storage_key
        end

        def metadata
          @metadata ||= MetadataFileReader.new(configuration).read
        end

        def configuration
          bulk_import.offline_configuration
        end

        def logger
          @logger ||= ::BulkImports::Logger.build
        end
      end
    end
  end
end
