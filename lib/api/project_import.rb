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
      not_found! unless Gitlab::CurrentSettings.import_sources.include?('gitlab_project')
    end

    resource :projects, requirements: { id: %r{[^/]+} } do

      params do
        requires :path, type: String, desc: 'The new project path and name'
        optional :namespace, type: String, desc: 'The ID or name of the namespace that the project will be imported into. Defaults to the user namespace.'
        requires :file, type: File, desc: 'The project export file to be imported'
      end
      desc 'Get export status' do
        success Entities::ProjectImportStatus
      end
      post 'import' do
        render_api_error!('The file is invalid', 400) unless file_is_valid?

        namespace = import_params[:namespace]

        namespace = if namespace && namespace =~ /^\d+$/
                      Namespace.find_by(id: namespace)
                    elsif namespace.blank?
                      current_user.namespace
                    else
                      Namespace.find_by_path_or_name(namespace)
                    end

        project_params = import_params.merge(namespace_id: namespace.id,
                                             file: import_params[:file]['tempfile'])
        project = ::Projects::GitlabProjectsImportService.new(current_user, project_params).execute

        render_api_error!(project&.full_messages&.first, 400) unless project&.saved?

        present project, with: Entities::ProjectImportStatus
      end

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      desc 'Get export status' do
        success Entities::ProjectImportStatus
      end
      get ':id/import' do
        present user_project, with: Entities::ProjectImportStatus
      end
    end
  end
end
