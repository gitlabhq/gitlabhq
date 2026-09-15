# frozen_string_literal: true

module Import
  module Offline
    module Imports
      class ScheduleImportService
        include Gitlab::Utils::StrongMemoize

        ValidationError = Class.new(StandardError)

        # @param [BulkImport] bulk_import
        # @param [Array<Hash>] entities
        # @param [Hash, nil] import_all a hash with a single destination_namespace, to
        #   import every top-level group in the export instead of the given entities
        def initialize(bulk_import, entities, import_all = nil)
          @bulk_import = bulk_import
          @entities = entities.map(&:deep_symbolize_keys)
          @import_all = import_all&.deep_symbolize_keys
        end

        def execute
          update_bulk_import
          create_entities(bulk_import)
          cache_source_ghost_user_id

          ::Import::BulkImports::EphemeralData.new(bulk_import.id).enable_importer_user_mapping
          BulkImportWorker.perform_async(bulk_import.id)

          ServiceResponse.success
        rescue ValidationError, MetadataFileReader::MetadataError => e
          logger.error(
            message: e.message,
            bulk_import_id: bulk_import.id,
            importer: Import::SOURCE_OFFLINE_TRANSFER.to_s
          )
          bulk_import.fail_op!
          ServiceResponse.error(message: e.message)
        end

        private

        attr_reader :bulk_import, :entities, :import_all

        def update_bulk_import
          bulk_import.update!(
            source_version: metadata[:instance_version],
            source_enterprise: metadata[:instance_enterprise]
          )

          configuration.update!(
            entity_prefix_mapping: metadata[:entities_mapping],
            source_hostname: metadata[:source_hostname]
          )
        end

        def create_entities(bulk_import)
          ::BulkImports::Entity.by_bulk_import_id(bulk_import.id).delete_all

          log_skipped_paths if import_all && root_group_paths.present?

          entities = entities_to_create

          entities.map { |entity_params| entity_params[:destination_namespace] }.uniq.each do |namespace|
            track_access_level(namespace)
          end

          entities.each do |entity_params|
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

        def cache_source_ghost_user_id
          ::BulkImports::SourceInternalUserFinder.cache_ghost_user_id(
            bulk_import.id,
            metadata[:source_ghost_user_id]
          )
        end

        # Importing an entire export derives its entities from the export's metadata,
        # which #update_bulk_import has already written to the configuration. Only
        # top-level groups become entities; their descendants are created later by
        # ProjectEntitiesPipeline and SubgroupEntitiesPipeline.
        def entities_to_create
          return Array.wrap(entities) unless import_all
          raise ValidationError, 'Export contains no top-level groups to import' if root_group_paths.empty?

          valid_entities = root_group_paths.filter_map { |path| import_all_entity_params(path) }
          raise ValidationError, 'No top-level groups have a valid destination' if valid_entities.empty?

          valid_entities
        end

        def root_group_paths
          configuration.root_group_paths
        end
        strong_memoize_attr :root_group_paths

        # The destination slug for import_all is the source group's own path, which
        # isn't known until the export's metadata is read above, so it can't be
        # validated alongside the entities path in CreateService#destinations_valid?.
        def import_all_entity_params(path)
          destination_validator.validate_destination_slug!(path)
          destination_validator.validate_destination_full_path_in_batch!(
            import_all_full_path(path), import_all_candidate_full_paths
          )

          {
            source_type: ::BulkImports::Entity::GROUP_ENTITY_SOURCE_TYPE,
            source_full_path: path,
            destination_slug: path,
            destination_namespace: import_all[:destination_namespace]
          }
        rescue ::BulkImports::Error => e
          logger.warn(
            message: "Skipping import_all entity with invalid destination: #{e.message}",
            source_full_path: path,
            bulk_import_id: bulk_import.id,
            importer: Import::SOURCE_OFFLINE_TRANSFER.to_s
          )
          nil
        end

        def import_all_full_path(path)
          [import_all[:destination_namespace], path].reject(&:blank?).join('/')
        end

        def import_all_candidate_full_paths
          root_group_paths.map { |path| import_all_full_path(path) }
        end
        strong_memoize_attr :import_all_candidate_full_paths

        def destination_validator
          @destination_validator ||= ::Import::Framework::DestinationValidator.new(current_user: bulk_import.user)
        end

        def log_skipped_paths
          skipped_paths = configuration.paths_without_exported_root
          return if skipped_paths.empty?

          logger.warn(
            message: 'Skipping entities whose top-level group is not in the export',
            skipped_paths: skipped_paths,
            bulk_import_id: bulk_import.id,
            importer: Import::SOURCE_OFFLINE_TRANSFER.to_s
          )
        end

        def track_access_level(destination_namespace)
          ::Import::Framework::UserRoleTracker
            .new(
              current_user: bulk_import.user,
              tracking_class_name: self.class.name,
              import_type: 'offline_import_group'
            )
            .track(destination_namespace)
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
