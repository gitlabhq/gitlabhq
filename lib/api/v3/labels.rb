module API
  module V3
    class Labels < Grape::API
      before { authenticate! }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: { id: %r{[^/]+} } do
        desc 'Get all labels of the project' do
          success ::API::Entities::Label
        end
        get ':id/labels' do
          present available_labels_for(user_project), with: ::API::Entities::Label, current_user: current_user, project: user_project
        end

        desc 'Delete an existing label' do
          success ::API::Entities::Label
        end
        params do
          requires :name, type: String, desc: 'The name of the label to be deleted'
        end
        delete ':id/labels' do
          authorize! :admin_label, user_project

          label = user_project.labels.find_by(title: params[:name])
          not_found!('Label') unless label

          present label.destroy, with: ::API::Entities::Label, current_user: current_user, project: user_project
        end
      end
    end
  end
end
