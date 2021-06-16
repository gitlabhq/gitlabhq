# frozen_string_literal: true

module BulkImports
  class RelationExportService
    include Gitlab::ImportExport::CommandLineUtil

    def initialize(user, portable, relation, jid)
      @user = user
      @portable = portable
      @relation = relation
      @jid = jid
    end

    def execute
      find_or_create_export! do |export|
        remove_existing_export_file!(export)
        serialize_relation_to_file(export.relation_definition)
        compress_exported_relation
        upload_compressed_file(export)
      end
    end

    private

    attr_reader :user, :portable, :relation, :jid

    def find_or_create_export!
      validate_user_permissions!

      export = portable.bulk_import_exports.safe_find_or_create_by!(relation: relation)
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

    def serialize_relation_to_file(relation_definition)
      serializer.serialize_relation(relation_definition)
    end

    def compress_exported_relation
      gzip(dir: export_path, filename: ndjson_filename)
    end

    def upload_compressed_file(export)
      compressed_filename = File.join(export_path, "#{ndjson_filename}.gz")
      upload = ExportUpload.find_or_initialize_by(export_id: export.id) # rubocop: disable CodeReuse/ActiveRecord

      File.open(compressed_filename) { |file| upload.export_file = file }

      upload.save!
    end

    def config
      @config ||= FileTransfer.config_for(portable)
    end

    def export_path
      @export_path ||= config.export_path
    end

    def portable_tree
      @portable_tree ||= config.portable_tree
    end

    # rubocop: disable CodeReuse/Serializer
    def serializer
      @serializer ||= ::Gitlab::ImportExport::Json::StreamingSerializer.new(
        portable,
        portable_tree,
        json_writer,
        exportable_path: ''
      )
    end
    # rubocop: enable CodeReuse/Serializer

    def json_writer
      @json_writer ||= ::Gitlab::ImportExport::Json::NdjsonWriter.new(export_path)
    end

    def ndjson_filename
      @ndjson_filename ||= "#{relation}.ndjson"
    end
  end
end
