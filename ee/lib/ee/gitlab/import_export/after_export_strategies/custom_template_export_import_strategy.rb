module EE
  module Gitlab
    module ImportExport
      module AfterExportStrategies
        class CustomTemplateExportImportStrategy < ::Gitlab::ImportExport::AfterExportStrategies::BaseAfterExportStrategy
          include ::Gitlab::Utils::StrongMemoize
          include ::Gitlab::TemplateHelper

          validates :export_into_project_id, presence: true

          attr_reader :params

          def initialize(export_into_project_id:)
            super

            @params = {}
          end

          protected

          def strategy_execute
            return unless export_into_project_exists?

            prepare_template_environment(export_file)

            set_import_attributes

            ::RepositoryImportWorker.new.perform(export_into_project_id)
          ensure
            project.remove_exported_project_file
          end

          def export_file
            strong_memoize(:export_file) do
              if object_storage?
                project.import_export_upload.export_file&.file
              else
                File.open(project.export_project_path)
              end
            end
          end

          def set_import_attributes
            ::Project.update(export_into_project_id, params)
          end

          def export_into_project_exists?
            ::Project.exists?(export_into_project_id)
          end
        end
      end
    end
  end
end
