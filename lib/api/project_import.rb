module API
  class ProjectImport < Grape::API
    include PaginationParams
    include Helpers::ProjectsHelpers

    helpers do
      def import_params
        declared_params(include_missing: false)
      end

      def file_is_valid?
        import_params[:file] && import_params[:file]['tempfile'].respond_to?(:read)
      end

      def validate_file!
        render_api_error!('The file is invalid', 400) unless file_is_valid?
      end
    end

    before do
      forbidden! unless Gitlab::CurrentSettings.import_sources.include?('gitlab_project')
    end

    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      params do
        requires :path, type: String, desc: 'The new project path and name'
        requires :file, type: File, desc: 'The project export file to be imported'
        optional :namespace, type: String, desc: "The ID or name of the namespace that the project will be imported into. Defaults to the current user's namespace."
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
        validate_file!

        Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42437')

        namespace = if import_params[:namespace]
                      find_namespace!(import_params[:namespace])
                    else
                      current_user.namespace
                    end

        project_params = {
            path: import_params[:path],
            namespace_id: namespace.id,
            file: import_params[:file]['tempfile']
        }

        override_params = import_params.delete(:override_params)

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
