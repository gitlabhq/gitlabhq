# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class TreeSaver
        attr_reader :full_path

        def initialize(project:, current_user:, shared:, params: {})
          @params       = params
          @project      = project
          @current_user = current_user
          @shared       = shared
        end

        def save
          ImportExport::Json::StreamingSerializer.new(
            exportable,
            reader.project_tree,
            json_writer,
            exportable_path: "project"
          ).execute

          true
        rescue StandardError => e
          @shared.error(e)
          false
        ensure
          json_writer&.close
        end

        private

        def reader
          @reader ||= Gitlab::ImportExport::Reader.new(shared: @shared)
        end

        def exportable
          @project.present(**exportable_params)
        end

        def exportable_params
          params = {
            presenter_class: presenter_class,
            current_user: @current_user
          }
          params[:override_description] = @params[:description] if @params[:description].present?
          params
        end

        def presenter_class
          Projects::ImportExport::ProjectExportPresenter
        end

        def json_writer
          @json_writer ||= begin
            if ::Feature.enabled?(:project_export_as_ndjson, @project.namespace, default_enabled: true)
              full_path = File.join(@shared.export_path, 'tree')
              Gitlab::ImportExport::Json::NdjsonWriter.new(full_path)
            else
              full_path = File.join(@shared.export_path, ImportExport.project_filename)
              Gitlab::ImportExport::Json::LegacyWriter.new(full_path, allowed_path: 'project')
            end
          end
        end
      end
    end
  end
end
