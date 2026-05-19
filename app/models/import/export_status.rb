# frozen_string_literal: true

module Import
  class ExportStatus
    include Gitlab::Utils::StrongMemoize

    CACHE_KEY = 'bulk_imports/export_status/%{entity_id}/%{relation}'

    # @param pipeline_tracker [BulkImports::Tracker] the current pipeline tracker for the import
    # @param relation [String] the relation being exported
    # @return [Import::Offline::ExportStatus, BulkImports::ExportStatus] the appropriate export status instance
    def self.for_context(pipeline_tracker, relation)
      if pipeline_tracker.entity.bulk_import.offline_export?
        Import::Offline::ExportStatus.new(pipeline_tracker, relation)
      else
        ::BulkImports::ExportStatus.new(pipeline_tracker, relation)
      end
    end

    # @param pipeline_tracker [BulkImports::Tracker] the pipeline tracker for the import
    # @param relation [String] the relation being exported
    def initialize(pipeline_tracker, relation)
      @pipeline_tracker = pipeline_tracker
      @relation = relation
      @entity = @pipeline_tracker.entity
    end

    # @return [Boolean] whether the export is currently in progress
    def in_progress?
      raise Gitlab::AbstractMethodError
    end

    # @return [Boolean] whether the export has failed
    def failed?
      raise Gitlab::AbstractMethodError
    end

    # @return [Boolean] whether the export is waiting to start
    def waiting_on_export?
      raise Gitlab::AbstractMethodError
    end

    # @return [String, nil] the error message if the export failed
    def error
      raise Gitlab::AbstractMethodError
    end

    # @return [Boolean] whether the export is split into batches
    def batched?
      raise Gitlab::AbstractMethodError
    end

    # @return [Integer] the total number of batches
    def batches_count
      raise Gitlab::AbstractMethodError
    end

    # @return [Array<Integer>] all batch numbers for the export
    def all_batch_numbers
      raise Gitlab::AbstractMethodError
    end

    # @param _batch_number [Integer] the batch number to check
    # @return [Boolean] whether the given batch has failed
    def batch_failed?(_batch_number)
      raise Gitlab::AbstractMethodError
    end

    # @param _batch_number [Integer] the batch number to check
    # @return [String, nil] the error message for the given batch
    def batch_error(_batch_number)
      raise Gitlab::AbstractMethodError
    end

    # @return [Integer] the total number of objects to export
    def total_objects_count
      raise Gitlab::AbstractMethodError
    end

    private

    attr_reader :entity, :relation, :pipeline_tracker

    def status_from_cache
      status = Gitlab::Cache::Import::Caching.read(cache_key)

      Gitlab::Json.safe_parse(status) if status
    end

    def cache_status(status)
      Gitlab::Cache::Import::Caching.write(cache_key, status.to_json)
    end

    def cache_key(cache_key_template = CACHE_KEY)
      Kernel.format(cache_key_template, entity_id: entity.id, relation: relation)
    end
  end
end
