# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class RelationSaver
        def initialize(project:, shared:, relation:, user:, params: {})
          @project = project
          @relation = relation
          @shared = shared
          @user = user
          @params = params
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

        attr_reader :project, :relation, :shared, :user, :params

        def serializer
          @serializer ||= ::Gitlab::ImportExport::Json::StreamingSerializer.new(
            presented_project_for_export,
            reader.project_tree,
            json_writer,
            exportable_path: 'tree/project',
            current_user: user
          )
        end

        def presented_project_for_export
          presentable_params = {
            presenter_class: Projects::ImportExport::ProjectExportPresenter,
            current_user: user
          }
          presentable_params[:override_description] = params[:description] if params[:description].present?

          project.present(**presentable_params)
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
