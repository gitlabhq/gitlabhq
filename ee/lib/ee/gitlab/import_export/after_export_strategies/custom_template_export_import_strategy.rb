module EE
  module Gitlab
    module ImportExport
      module AfterExportStrategies
        class CustomTemplateExportImportStrategy < ::Gitlab::ImportExport::AfterExportStrategies::BaseAfterExportStrategy
          include ::Gitlab::Utils::StrongMemoize
          include ::Gitlab::TemplateHelper

          validates :export_into_project_id, presence: true

          def initialize(export_into_project_id:)
            super
          end

          protected

          def strategy_execute
            return unless export_into_project_exists?

            prepare_template_environment(export_file_path)

            set_import_attributes

            ::RepositoryImportWorker.new.perform(export_into_project_id)
          ensure
            project.remove_exported_project_file
          end

          def export_file_path
            strong_memoize(:export_file_path) do
              if object_storage?
                project.import_export_upload.export_file.path
              else
                project.export_project_path
              end
            end
          end

          def set_import_attributes
            ::Project.update(export_into_project_id, import_source: import_upload_path)
          end

          def export_into_project_exists?
            ::Project.exists?(export_into_project_id)
          end
        end
      end
    end
  end
end
