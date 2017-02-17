module API
  module V3
    class Labels < Grape::API
      before { authenticate! }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects do
        desc 'Get all labels of the project' do
          success ::API::Entities::Label
        end
        get ':id/labels' do
          present available_labels, with: ::API::Entities::Label, current_user: current_user, project: user_project
        end
      end
    end
  end
end
