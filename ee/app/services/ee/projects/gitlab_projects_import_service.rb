module EE
  module Projects
    module GitlabProjectsImportService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      override :execute
      def execute
        super.tap do |project|
          if project.saved? && custom_template
            custom_template.add_export_job(current_user: current_user,
                                           after_export_strategy: export_strategy(project))
          end
        end
      end

      private

      override :prepare_import_params
      def prepare_import_params
        super

        if custom_template
          params[:import_type] = 'gitlab_custom_project_template'
        end
      end

      def custom_template
        strong_memoize(:custom_template) do
          params.delete(:custom_template)
        end
      end

      def export_strategy(project)
        Gitlab::ImportExport::AfterExportStrategies::CustomTemplateExportImportStrategy.new(export_into_project_id: project.id)
      end
    end
  end
end
