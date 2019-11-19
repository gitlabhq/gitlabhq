# frozen_string_literal: true

module API
  class GroupExport < Grape::API
    before do
      authorize! :admin_group, user_group
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: { id: %r{[^/]+} } do
      desc 'Download export' do
        detail 'This feature was introduced in GitLab 12.5.'
      end
      get ':id/export/download' do
        if user_group.export_file_exists?
          present_carrierwave_file!(user_group.export_file)
        else
          render_api_error!('404 Not found or has expired', 404)
        end
      end

      desc 'Start export' do
        detail 'This feature was introduced in GitLab 12.5.'
      end
      post ':id/export' do
        GroupExportWorker.perform_async(current_user.id, user_group.id, params)

        accepted!
      end
    end
  end
end
