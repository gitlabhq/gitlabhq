module API
  module V3
    class Triggers < Grape::API
      include PaginationParams

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects do
        desc 'Delete a trigger' do
          success ::API::Entities::Trigger
        end
        params do
          requires :token, type: String, desc: 'The unique token of trigger'
        end
        delete ':id/triggers/:token' do
          authenticate!
          authorize! :admin_build, user_project

          trigger = user_project.triggers.find_by(token: params[:token].to_s)
          return not_found!('Trigger') unless trigger

          trigger.destroy

          present trigger, with: ::API::Entities::Trigger
        end
      end
    end
  end
end
