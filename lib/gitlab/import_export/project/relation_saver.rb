# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class RelationSaver
        def initialize(project:, shared:, relation:)
          @project = project
          @relation = relation
          @shared = shared
        end

        def save
          if root_relation?
            serializer.serialize_root
          else
            serializer.serialize_relation(relation_schema)
          end

          true
        rescue StandardError => e
          shared.error(e)
          false
        end

        private

        attr_reader :project, :relation, :shared

        def serializer
          @serializer ||= ::Gitlab::ImportExport::Json::StreamingSerializer.new(
            project,
            reader.project_tree,
            json_writer,
            exportable_path: 'tree/project',
            current_user: nil
          )
        end

        def root_relation?
          relation == Projects::ImportExport::RelationExport::ROOT_RELATION
        end

        def relation_schema
          reader.project_tree[:include].find { |include| include[relation.to_sym] }
        end

        def reader
          @reader ||= ::Gitlab::ImportExport::Reader.new(shared: shared)
        end

        def json_writer
          @json_writer ||= ::Gitlab::ImportExport::Json::NdjsonWriter.new(shared.export_path)
        end
      end
    end
  end
end
