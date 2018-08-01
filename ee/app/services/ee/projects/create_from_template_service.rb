module EE
  module Projects
    module CreateFromTemplateService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      override :execute
      def execute
        return super unless use_custom_template?

        override_params = params.dup
        params[:custom_template] = template_project if template_project

        ::Projects::GitlabProjectsImportService.new(current_user, params, override_params).execute
      end

      private

      def use_custom_template?
        strong_memoize(:use_custom_template) do
          template_name &&
            ::Gitlab::Utils.to_boolean(params.delete(:use_custom_template)) &&
            ::Gitlab::CurrentSettings.custom_project_templates_enabled?
        end
      end

      def template_project
        strong_memoize(:template_project) do
          current_user.available_custom_project_templates(search: template_name).first
        end
      end
    end
  end
end
