# frozen_string_literal: true

module BulkImports
  class TreeExportService
    def initialize(portable, export_path, relation, user)
      @portable = portable
      @export_path = export_path
      @relation = relation
      @config = FileTransfer.config_for(portable)
      @user = user
    end

    def execute
      return serializer.serialize_root(config.class::SELF_RELATION) if self_relation?

      relation_definition = config.tree_relation_definition_for(relation)

      raise BulkImports::Error, 'Unsupported relation export type' unless relation_definition

      serializer.serialize_relation(relation_definition)
    end

    def exported_filename
      return "#{relation}.json" if self_relation?

      "#{relation}.ndjson"
    end

    private

    attr_reader :export_path, :portable, :relation, :config, :user

    # rubocop: disable CodeReuse/Serializer
    def serializer
      ::Gitlab::ImportExport::Json::StreamingSerializer.new(
        portable,
        config.portable_tree,
        json_writer,
        exportable_path: '',
        current_user: user
      )
    end
    # rubocop: enable CodeReuse/Serializer

    def json_writer
      ::Gitlab::ImportExport::Json::NdjsonWriter.new(export_path)
    end

    def self_relation?
      relation == config.class::SELF_RELATION
    end
  end
end
