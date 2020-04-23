# frozen_string_literal: true

# This service is an adapter used to for the GitLab Import feature, and
# creating a project from a template.
# The latter will under the hood just import an archive supplied by GitLab.
module Projects
  class GitlabProjectsImportService
    include Gitlab::Utils::StrongMemoize
    include Gitlab::TemplateHelper

    attr_reader :current_user, :params

    def initialize(user, import_params, override_params = nil)
      @current_user, @params, @override_params = user, import_params.dup, override_params
    end

    def execute(options = {})
      measurement_enabled = !!options[:measurement_enabled]
      measurement_logger = options[:measurement_logger]

      ::Gitlab::Utils::Measuring.execute_with(measurement_enabled, measurement_logger, base_log_data) do
        prepare_template_environment(template_file)

        prepare_import_params

        ::Projects::CreateService.new(current_user, params).execute
      end
    end

    private

    def base_log_data
      base_log_data = {
        class: self.class.name,
        current_user: current_user.name,
        project_full_path: project_path
      }

      if template_file
        base_log_data[:import_type] = 'gitlab_project'
        base_log_data[:file_path] = template_file.path
      end

      base_log_data
    end

    def overwrite_project?
      overwrite? && project_with_same_full_path?
    end

    def project_with_same_full_path?
      Project.find_by_full_path(project_path).present?
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def current_namespace
      strong_memoize(:current_namespace) do
        Namespace.find_by(id: params[:namespace_id]) || current_user.namespace
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def project_path
      "#{current_namespace.full_path}/#{params[:path]}"
    end

    def overwrite?
      strong_memoize(:overwrite) do
        params.delete(:overwrite)
      end
    end

    def template_file
      strong_memoize(:template_file) do
        params.delete(:file)
      end
    end

    def prepare_import_params
      data = {}
      data[:override_params] = @override_params if @override_params

      if overwrite_project?
        data[:original_path] = params[:path]
        params[:path] += "-#{tmp_filename}"
      end

      if template_file
        params[:import_type] = 'gitlab_project'
      end

      params[:import_data] = { data: data } if data.present?
    end
  end
end

Projects::GitlabProjectsImportService.prepend_if_ee('EE::Projects::GitlabProjectsImportService')
