# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class ExportTask < BaseTask
        def initialize(*)
          super

          @project = namespace.projects.find_by_path(@project_path)
        end

        def export
          return error("Project with path: #{project_path} was not found. Please provide correct project path") unless project
          return error("Invalid file path: #{file_path}. Please provide correct file path") unless file_path_exists?

          with_export do
            ::Projects::ImportExport::ExportService.new(project, current_user)
              .execute(Gitlab::ImportExport::AfterExportStrategies::MoveFileStrategy.new(archive_path: file_path), measurement_options)
          end

          success('Done!')
        end

        private

        def file_path_exists?
          directory = File.dirname(file_path)

          Dir.exist?(directory)
        end

        def with_export
          with_request_store do
            ::Gitlab::GitalyClient.allow_n_plus_1_calls do
              yield
            end
          end
        end
      end
    end
  end
end
