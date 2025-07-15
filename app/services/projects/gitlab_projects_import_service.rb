# frozen_string_literal: true

# This service is an adapter used to for the GitLab Import feature, and
# creating a project from a template.
# The latter will under the hood just import an archive supplied by GitLab.
module Projects
  class GitlabProjectsImportService
    include Gitlab::Utils::StrongMemoize
    include Gitlab::TemplateHelper

    attr_reader :current_user, :params

    def initialize(user, import_params, override_params = nil, import_type:)
      @current_user = user
      @params = import_params.dup
      @override_params = override_params
      @import_type = import_type.to_s

      raise ArgumentError, 'Invalid import_type provided' unless valid_import_type?
    end

    def execute
      prepare_template_environment(template_file, current_user)

      prepare_import_params

      ::Projects::CreateService.new(current_user, params).execute
    end

    private

    attr_reader :import_type

    def valid_import_type?
      import_type == 'gitlab_project' || Gitlab::ImportSources.template?(import_type)
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

      data[:sample_data] = params.delete(:sample_data) if template_file && params.key?(:sample_data)

      params[:import_type] = import_type
      params[:organization_id] = current_namespace.organization_id
      params[:import_data] = { data: data } if data.present?
    end
  end
end

Projects::GitlabProjectsImportService.prepend_mod_with('Projects::GitlabProjectsImportService')
