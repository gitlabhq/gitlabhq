# frozen_string_literal: true

module API
  module Terraform
    class State < Grape::API
      before { authenticate! }
      before { authorize! :admin_terraform_state, user_project }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        params do
          requires :name, type: String, desc: 'The name of a terraform state'
        end
        namespace ':id/terraform/state/:name' do
          desc 'Get a terraform state by its name'
          route_setting :authentication, basic_auth_personal_access_token: true
          get do
            status 501
            content_type 'text/plain'
            body 'not implemented'
          end

          desc 'Add a new terraform state or update an existing one'
          route_setting :authentication, basic_auth_personal_access_token: true
          post do
            status 501
            content_type 'text/plain'
            body 'not implemented'
          end

          desc 'Delete a terraform state of certain name'
          route_setting :authentication, basic_auth_personal_access_token: true
          delete do
            status 501
            content_type 'text/plain'
            body 'not implemented'
          end
        end
      end
    end
  end
end
