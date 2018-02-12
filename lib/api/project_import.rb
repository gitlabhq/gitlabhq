module API
  class ProjectImport < Grape::API
    include PaginationParams

    helpers do
      def import_params
        declared_params(include_missing: false)
      end

      def file_is_valid?
        import_params[:file] && import_params[:file].respond_to?(:read)
      end
    end

    before do
      not_found! unless Gitlab::CurrentSettings.import_sources.include?('gitlab_project')
    end

    params do
      requires :name, type: String, desc: 'The new project name'
      optional :namespace, type: String, desc: 'The ID or name of the namespace that the project will be imported into. Defaults to the user namespace.'
      requires :file, type: File, desc: 'The project export file to be imported'
    end
    resource :projects do
      desc 'Get export status' do
        success Entities::ProjectImportStatus
      end
      post 'import' do
        render_api_error!('The branch refname is invalid', 400) unless file_is_valid?

        namespace = import_params[:namespace]

        namespace = if namespace && namespace =~ /^\d+$/
                      Namespace.find_by(id: namespace)
                    elsif namespace.blank?
                      current_user.namespace
                    else
                      Namespace.find_by_path_or_name(namespace)
                    end

        project_params = import_params.merge(namespace: namespace.id)

        project = ::Projects::GitlabProjectsImportService.new(current_user, project_params).execute

        render_api_error!(project.full_messages.first, 400) unless project.saved?

        present project, with: Entities::ProjectImportStatus
      end
    end
  end
end
