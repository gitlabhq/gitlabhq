# frozen_string_literal: true

module BulkImports
  class TreeExportService
    include Gitlab::Utils::StrongMemoize

    delegate :exported_objects_count, to: :serializer

    def initialize(portable, export_path, relation, user)
      @portable = portable
      @export_path = export_path
      @relation = relation
      @config = FileTransfer.config_for(portable)
      @user = user
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

    attr_reader :export_path, :portable, :relation, :config, :user

    # rubocop: disable CodeReuse/Serializer
    def serializer
      @serializer ||= ::Gitlab::ImportExport::Json::StreamingSerializer.new(
        portable,
        config.portable_tree,
        ::Gitlab::ImportExport::Json::NdjsonWriter.new(export_path),
        exportable_path: '',
        current_user: user
      )
    end
    # rubocop: enable CodeReuse/Serializer

    def extension
      return 'json' if self_relation?(relation)

      'ndjson'
    end

    def relation_definition
      definition = config.tree_relation_definition_for(relation)

      raise BulkImports::Error, 'Unsupported relation export type' unless definition

      definition
    end
    strong_memoize_attr :relation_definition
  end
end
