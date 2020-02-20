# frozen_string_literal: true

module API
  class ProjectImport < Grape::API
    include PaginationParams

    helpers Helpers::ProjectsHelpers
    helpers Helpers::FileUploadHelpers

    helpers do
      def import_params
        declared_params(include_missing: false)
      end

      def throttled?(key, scope)
        rate_limiter.throttled?(key, scope: scope)
      end

      def rate_limiter
        ::Gitlab::ApplicationRateLimiter
      end
    end

    before do
      forbidden! unless Gitlab::CurrentSettings.import_sources.include?('gitlab_project')
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      params do
        requires :path, type: String, desc: 'The new project path and name'
        # TODO: remove rubocop disable - https://gitlab.com/gitlab-org/gitlab/issues/14960
        requires :file, type: File, desc: 'The project export file to be imported' # rubocop:disable Scalability/FileUploads
        optional :name, type: String, desc: 'The name of the project to be imported. Defaults to the path of the project if not provided.'
        optional :namespace, type: String, desc: "The ID or name of the namespace that the project will be imported into. Defaults to the current user's namespace."
        optional :overwrite, type: Boolean, default: false, desc: 'If there is a project in the same namespace and with the same name overwrite it'
        optional :override_params,
                 type: Hash,
                 desc: 'New project params to override values in the export' do
          use :optional_project_params
        end
      end
      desc 'Create a new project import' do
        detail 'This feature was introduced in GitLab 10.6.'
        success Entities::ProjectImportStatus
      end
      post 'import' do
        key = "project_import".to_sym

        if throttled?(key, [current_user, key])
          rate_limiter.log_request(request, "#{key}_request_limit".to_sym, current_user)

          render_api_error!({ error: _('This endpoint has been requested too many times. Try again later.') }, 429)
        end

        validate_file!

        Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-foss/issues/42437')

        namespace = if import_params[:namespace]
                      find_namespace!(import_params[:namespace])
                    else
                      current_user.namespace
                    end

        project_params = {
            path: import_params[:path],
            namespace_id: namespace.id,
            name: import_params[:name],
            file: import_params[:file]['tempfile'],
            overwrite: import_params[:overwrite]
        }

        override_params = import_params.delete(:override_params)
        filter_attributes_using_license!(override_params) if override_params

        project = ::Projects::GitlabProjectsImportService.new(
          current_user, project_params, override_params
        ).execute

        render_api_error!(project.errors.full_messages&.first, 400) unless project.saved?

        present project, with: Entities::ProjectImportStatus
      end

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      desc 'Get a project export status' do
        detail 'This feature was introduced in GitLab 10.6.'
        success Entities::ProjectImportStatus
      end
      get ':id/import' do
        present user_project, with: Entities::ProjectImportStatus
      end
    end
  end
end
