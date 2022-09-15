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
        remove_existing_export_file!(export)
        export_service.execute
        compress_exported_relation
        upload_compressed_file(export)
      end
    ensure
      FileUtils.remove_entry(config.export_path)
    end

    private

    attr_reader :user, :portable, :relation, :jid, :config

    def find_or_create_export!
      validate_user_permissions!

      export = portable.bulk_import_exports.safe_find_or_create_by!(relation: relation)

      return export if export.finished? && export.updated_at > EXISTING_EXPORT_TTL.ago

      export.update!(status_event: 'start', jid: jid)

      yield export

      export.update!(status_event: 'finish', error: nil)
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, portable_id: portable.id, portable_type: portable.class.name)

      export&.update(status_event: 'fail_op', error: e.class)
    end

    def validate_user_permissions!
      ability = "admin_#{portable.to_ability_name}"

      user.can?(ability, portable) ||
        raise(::Gitlab::ImportExport::Error.permission_error(user, portable))
    end

    def remove_existing_export_file!(export)
      upload = export.upload

      return unless upload&.export_file&.file

      upload.remove_export_file!
      upload.save!
    end

    def export_service
      @export_service ||= if config.tree_relation?(relation) || config.self_relation?(relation)
                            TreeExportService.new(portable, config.export_path, relation, user)
                          elsif config.file_relation?(relation)
                            FileExportService.new(portable, config.export_path, relation)
                          else
                            raise BulkImports::Error, 'Unsupported export relation'
                          end
    end

    def upload_compressed_file(export)
      compressed_file = File.join(config.export_path, "#{export_service.exported_filename}.gz")

      upload = ExportUpload.find_or_initialize_by(export_id: export.id) # rubocop: disable CodeReuse/ActiveRecord

      File.open(compressed_file) { |file| upload.export_file = file }

      upload.save!
    end

    def compress_exported_relation
      gzip(dir: config.export_path, filename: export_service.exported_filename)
    end
  end
end
