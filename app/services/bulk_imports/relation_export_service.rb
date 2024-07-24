# frozen_string_literal: true

module BulkImports
  class RelationExportService
    include Gitlab::ImportExport::CommandLineUtil

    EXISTING_EXPORT_TTL = 3.minutes

    def initialize(user, portable, relation, jid)
      @user = user
      @portable = portable
      @relation = relation
      @jid = jid
      @config = FileTransfer.config_for(portable)
    end

    def execute
      find_or_create_export! do |export|
        export.remove_existing_upload!
        export_service.execute
        ensure_export_file_exists!
        compress_exported_relation
        upload_compressed_file(export)
      end
    ensure
      FileUtils.remove_entry(export_path)
    end

    private

    attr_reader :user, :portable, :relation, :jid, :config

    delegate :export_path, to: :config

    def find_or_create_export!
      export = portable.bulk_import_exports.safe_find_or_create_by!(relation: relation, user: user)

      return export if export.finished? && export.updated_at > EXISTING_EXPORT_TTL.ago && !export.batched?

      start_export!(export)

      yield export

      finish_export!(export)
    end

    def export_service
      @export_service ||= if config.tree_relation?(relation) || config.self_relation?(relation)
                            TreeExportService.new(portable, export_path, relation, user)
                          elsif config.file_relation?(relation)
                            FileExportService.new(portable, export_path, relation, user)
                          else
                            raise BulkImports::Error, 'Unsupported export relation'
                          end
    end

    def upload_compressed_file(export)
      compressed_file = File.join(export_path, "#{export_service.exported_filename}.gz")

      upload = ExportUpload.find_or_initialize_by(export_id: export.id) # rubocop: disable CodeReuse/ActiveRecord

      File.open(compressed_file) { |file| upload.export_file = file }

      upload.save!
    end

    def compress_exported_relation
      gzip(dir: export_path, filename: export_service.exported_filename)
    end

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

    def finish_export!(export)
      export.update!(
        status_event: 'finish',
        batched: false,
        error: nil,
        total_objects_count: export_service.exported_objects_count
      )
    end

    def exported_filepath
      File.join(export_path, export_service.exported_filename)
    end

    # Create empty file on disk
    # if relation is empty and nothing was exported
    def ensure_export_file_exists!
      FileUtils.touch(exported_filepath)
    end
  end
end
