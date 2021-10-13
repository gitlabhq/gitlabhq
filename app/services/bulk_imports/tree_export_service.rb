# frozen_string_literal: true

module BulkImports
  class TreeExportService
    def initialize(portable, export_path, relation)
      @portable = portable
      @export_path = export_path
      @relation = relation
      @config = FileTransfer.config_for(portable)
    end

    def execute
      relation_definition = config.tree_relation_definition_for(relation)

      raise BulkImports::Error, 'Unsupported relation export type' unless relation_definition

      serializer.serialize_relation(relation_definition)
    end

    def exported_filename
      "#{relation}.ndjson"
    end

    private

    attr_reader :export_path, :portable, :relation, :config

    # rubocop: disable CodeReuse/Serializer
    def serializer
      ::Gitlab::ImportExport::Json::StreamingSerializer.new(
        portable,
        config.portable_tree,
        json_writer,
        exportable_path: ''
      )
    end
    # rubocop: enable CodeReuse/Serializer

    def json_writer
      ::Gitlab::ImportExport::Json::NdjsonWriter.new(export_path)
    end
  end
end
