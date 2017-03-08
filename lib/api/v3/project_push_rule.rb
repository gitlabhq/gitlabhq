module API
  module V3
    class ProjectPushRule < Grape::API
      before { authenticate! }
      before { authorize_admin_project }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects do
        desc 'Deletes project push rule'
        delete ":id/push_rule" do
          push_rule = user_project.push_rule
          not_found!('Push Rule') unless push_rule

          status(200)
          push_rule.destroy
        end
      end
    end
  end
end
