# frozen_string_literal: true

module BulkImports
  class RelationExportService
    include Gitlab::Utils::StrongMemoize
    include ::Import::BulkImports::ExportUploadable

    EXISTING_EXPORT_TTL = 3.minutes

    # @param offline_export_id [Integer] ID of offline transfer to which export is related
    def initialize(user, portable, relation, jid, offline_export_id: nil)
      @user = user
      @portable = portable
      @relation = relation
      @jid = jid
      @offline_export_id = offline_export_id
    end

    def execute
      export.remove_existing_upload!
      export_service.execute
      ensure_export_file_exists!
      compress_and_upload_export

      finish_export!
    ensure
      FileUtils.remove_entry(export_path)
    end

    private

    attr_reader :user, :portable, :relation, :jid, :offline_export_id

    def export
      export_params = { offline_export_id: offline_export_id, relation: relation }
      export_params[:user] = user unless offline_export_id

      export = portable.bulk_import_exports.safe_find_or_create_by!(export_params)

      return export if export.finished? && export.updated_at > EXISTING_EXPORT_TTL.ago && !export.batched?

      start_export!(export)

      export
    end
    strong_memoize_attr :export

    def upload
      ExportUpload.find_or_initialize_by(export_id: export.id) # rubocop: disable CodeReuse/ActiveRecord -- existing violation
    end
    strong_memoize_attr :upload

    def start_export!(export)
      export.update!(
        status_event: 'start',
        jid: jid,
        batched: false,
        batches_count: 0,
        total_objects_count: 0,
        error: nil
      )

      export.batches.destroy_all if export.batches.any? # rubocop:disable Cop/DestroyAll
    end

    def finish_export!
      export.update!(
        status_event: 'finish',
        batched: false,
        error: nil,
        total_objects_count: export_service.exported_objects_count
      )
    end

    # Create empty file on disk
    # if relation is empty and nothing was exported
    def ensure_export_file_exists!
      FileUtils.touch(exported_filepath)
    end
  end
end
