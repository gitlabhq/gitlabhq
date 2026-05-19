# frozen_string_literal: true

module BulkImports
  class TreeExportService
    include Gitlab::Utils::StrongMemoize

    delegate :exported_objects_count, to: :serializer

    # @param export [BulkImports::Export] the export record providing portable, relation, and offline_export_id
    # @param export_path [String] directory path where the exported file will be written
    # @param user [User] the user performing the export
    def initialize(export, export_path, user)
      @portable = export.portable
      @export_path = export_path
      @relation = export.relation
      @config = FileTransfer.config_for(portable)
      @user = user
      @offline_export_id = export.offline_export_id
    end

    def execute
      if self_relation?(relation)
        serializer.serialize_root(config.class::SELF_RELATION)
      else
        serializer.serialize_relation(relation_definition)
      end
    end

    def export_batch(ids)
      serializer.serialize_relation(relation_definition, batch_ids: Array.wrap(ids))
    end

    def exported_filename
      "#{relation}.#{extension}"
    end

    private

    delegate :self_relation?, to: :config

    attr_reader :export_path, :portable, :relation, :config, :user, :offline_export_id

    # rubocop: disable CodeReuse/Serializer
    def serializer
      @serializer ||= ::Gitlab::ImportExport::Json::StreamingSerializer.new(
        portable,
        config.portable_tree,
        ::Gitlab::ImportExport::Json::NdjsonWriter.new(export_path),
        exportable_path: '',
        current_user: user,
        offline_export_id: offline_export_id
      )
    end
    # rubocop: enable CodeReuse/Serializer

    def extension
      return 'json' if self_relation?(relation)

      'ndjson'
    end

    def relation_definition
      definition = config.tree_relation_definition_for(relation)

      raise BulkImports::Error, 'Unsupported tree relation export type' unless definition

      definition
    end
    strong_memoize_attr :relation_definition
  end
end
