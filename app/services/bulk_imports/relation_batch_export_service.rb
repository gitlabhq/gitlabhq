# frozen_string_literal: true

module BulkImports
  class RelationBatchExportService
    include Gitlab::ImportExport::CommandLineUtil

    def initialize(user, batch)
      @user = user
      @batch = batch
      @config = FileTransfer.config_for(portable)
    end

    def execute
      start_batch!

      batch_ids = relation_batch_ids
      return if batch_ids.blank?

      export_service.export_batch(batch_ids)
      compress_exported_relation
      upload_compressed_file
      export.touch

      finish_batch!
    ensure
      FileUtils.remove_entry(export_path)
    end

    private

    attr_reader :user, :batch, :config

    delegate :export_path, to: :config
    delegate :batch_number, :export, to: :batch
    delegate :portable, :relation, to: :export
    delegate :exported_filename, :exported_objects_count, to: :export_service

    def export_service
      @export_service ||= config.export_service_for(relation).new(portable, export_path, relation, user)
    end

    def compress_exported_relation
      gzip(dir: export_path, filename: exported_filename)
    end

    def upload_compressed_file
      File.open(compressed_filename) { |file| batch_upload.export_file = file }

      batch_upload.save!
    end

    def batch_upload
      @batch_upload ||= ::BulkImports::ExportUpload.find_or_initialize_by(export_id: export.id, batch_id: batch.id) # rubocop: disable CodeReuse/ActiveRecord
    end

    def compressed_filename
      File.join(export_path, "#{exported_filename}.gz")
    end

    def relation_batch_ids
      cache_values = Gitlab::Cache::Import::Caching.values_from_set(cache_key)

      if cache_values.blank?
        error_message = "Batched relation export cache key missing or expired."
        batch.update!(status_event: 'fail_op', error: error_message)
        Gitlab::ErrorTracking.track_exception(BulkImports::Error.new(error_message))
        return []
      end

      cache_values.map(&:to_i)
    end

    def cache_key
      BulkImports::BatchedRelationExportService.cache_key(export.id, batch.id)
    end

    def start_batch!
      batch.update!(status_event: 'start', objects_count: 0, error: nil)
    end

    def finish_batch!
      batch.update!(status_event: 'finish', objects_count: exported_objects_count, error: nil)
    end

    def exported_filepath
      File.join(export_path, exported_filename)
    end
  end
end
