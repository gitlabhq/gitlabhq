module API
  class ProjectImport < Grape::API
    include PaginationParams

    helpers do
      def import_params
        declared_params(include_missing: false)
      end

      def file_is_valid?
        import_params[:file] && import_params[:file]['tempfile'].respond_to?(:read)
      end
    end

    before do
      forbidden! unless Gitlab::CurrentSettings.import_sources.include?('gitlab_project')
    end

    resource :projects, requirements: { id: %r{[^/]+} } do
      params do
        requires :path, type: String, desc: 'The new project path and name'
        requires :file, type: File, desc: 'The project export file to be imported'
        optional :namespace, type: String, desc: 'The ID or name of the namespace that the project will be imported into. Defaults to the user namespace.'
      end
      desc 'Create a new project import' do
        success Entities::ProjectImportStatus
      end
      post 'import' do
        render_api_error!('The file is invalid', 400) unless file_is_valid?

        Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42437')

        namespace = import_params[:namespace]
        namespace = if namespace.blank?
                      current_user.namespace
                    elsif namespace =~ /^\d+$/
                      Namespace.find_by(id: namespace)
                    else
                      Namespace.find_by_path_or_name(namespace)
                    end

        project_params = import_params.merge(namespace_id: namespace.id,
                                             file: import_params[:file]['tempfile'])
        project = ::Projects::GitlabProjectsImportService.new(current_user, project_params).execute

        render_api_error!(project.errors.full_messages&.first, 400) unless project.saved?

        present project, with: Entities::ProjectImportStatus
      end

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      desc 'Get a project export status' do
        success Entities::ProjectImportStatus
      end
      get ':id/import' do
        present user_project, with: Entities::ProjectImportStatus
      end
    end
  end
end
