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
              .execute(Gitlab::ImportExport::AfterExportStrategies::MoveFileStrategy.new(archive_path: file_path))
          end

          return error(project.import_export_shared.errors.join(', ')) if project.import_export_shared.errors.any?

          success('Done!')
        rescue Gitlab::ImportExport::Error => e
          error(e.message)
        end

        private

        def file_path_exists?
          directory = File.dirname(file_path)

          Dir.exist?(directory)
        end

        def with_export
          ::Gitlab::SafeRequestStore.ensure_request_store do
            # We are disabling ObjectStorage for `export`
            # since when direct upload is enabled, remote storage will be used
            # and Gitlab::ImportExport::AfterExportStrategies::MoveFileStrategy will fail to copy exported archive
            disable_upload_object_storage do
              ::Gitlab::GitalyClient.allow_n_plus_1_calls do
                yield
              end
            end
          end
        end
      end
    end
  end
end
