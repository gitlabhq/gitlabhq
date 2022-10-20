# frozen_string_literal: true

module BulkImports
  class CreatePipelineTrackersService
    def initialize(entity)
      @entity = entity
    end

    def execute!
      entity.class.transaction do
        entity.pipelines.each do |pipeline|
          status = skip_pipeline?(pipeline) ? -2 : 0

          entity.trackers.create!(
            stage: pipeline[:stage],
            pipeline_name: pipeline[:pipeline],
            status: status
          )
        end
      end
    end

    private

    attr_reader :entity

    def skip_pipeline?(pipeline)
      return false unless source_version.valid?

      minimum_version, maximum_version = pipeline.values_at(:minimum_source_version, :maximum_source_version)

      if minimum_version && non_patch_source_version < Gitlab::VersionInfo.parse(minimum_version)
        log_skipped_pipeline(pipeline, minimum_version, maximum_version)
        return true
      end

      if maximum_version && non_patch_source_version > Gitlab::VersionInfo.parse(maximum_version)
        log_skipped_pipeline(pipeline, minimum_version, maximum_version)
        return true
      end

      false
    end

    def source_version
      @source_version ||= entity.bulk_import.source_version_info
    end

    def non_patch_source_version
      source_version.without_patch
    end

    def log_skipped_pipeline(pipeline, minimum_version, maximum_version)
      logger.info(
        message: 'Pipeline skipped as source instance version not compatible with pipeline',
        bulk_import_entity_id: entity.id,
        bulk_import_id: entity.bulk_import_id,
        bulk_import_entity_type: entity.source_type,
        source_full_path: entity.source_full_path,
        pipeline_name: pipeline[:pipeline],
        minimum_source_version: minimum_version,
        maximum_source_version: maximum_version,
        source_version: source_version.to_s,
        importer: 'gitlab_migration'
      )
    end

    def logger
      @logger ||= Gitlab::Import::Logger.build
    end
  end
end
