module API
  class ProjectExport < Grape::API
    before do
      not_found! unless Gitlab::CurrentSettings.project_export_enabled?
      authorize_admin_project
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: { id: %r{[^/]+} } do
      desc 'Get export status' do
        detail 'This feature was introduced in GitLab 10.6.'
        success Entities::ProjectExportStatus
      end
      get ':id/export' do
        present user_project, with: Entities::ProjectExportStatus
      end

      desc 'Download export' do
        detail 'This feature was introduced in GitLab 10.6.'
      end
      get ':id/export/download' do
        path = user_project.export_project_path

        render_api_error!('404 Not found or has expired', 404) unless path

        present_disk_file!(path, File.basename(path), 'application/gzip')
      end

      desc 'Start export' do
        detail 'This feature was introduced in GitLab 10.6.'
      end
      post ':id/export' do
        user_project.add_export_job(current_user: current_user)

        accepted!
      end
    end
  end
end
