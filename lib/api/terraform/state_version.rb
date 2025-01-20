# frozen_string_literal: true

module API
  module Terraform
    class StateVersion < ::API::Base
      default_format :json

      feature_category :infrastructure_as_code
      urgency :low

      before do
        authenticate!
        authorize! :read_terraform_state, user_project
      end

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end

      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        namespace ':id/terraform/state/:name/versions/:serial' do
          params do
            requires :name, type: String, desc: 'The name of a Terraform state'
            requires :serial, type: Integer, desc: 'The version number of the state'
          end

          helpers do
            def remote_state_handler
              ::Terraform::RemoteStateHandler.new(user_project, current_user, name: params[:name])
            end

            def find_version(serial)
              remote_state_handler.find_with_lock do |state|
                version = state.versions.find_by_version(serial)

                if version.present?
                  yield version
                else
                  not_found!
                end
              end
            end
          end

          desc 'Get a Terraform state version' do
            detail 'Get a Terraform state version'
            success File
            failure [
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not found' }
            ]
            tags %w[terraform_state]
          end
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
          route_setting :authorization, job_token_policies: :read_terraform_state
          get do
            find_version(params[:serial]) do |version|
              env['api.format'] = :binary # Bypass json serialization
              body version.file.read
              status :ok
            end
          end

          desc 'Delete a Terraform state version' do
            detail 'Delete a Terraform state version'
            success code: 204
            failure [
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not found' }
            ]
            tags %w[terraform_state]
          end
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
          route_setting :authorization, job_token_policies: :admin_terraform_state
          delete do
            authorize! :admin_terraform_state, user_project

            find_version(params[:serial]) do |version|
              version.destroy!

              body false
              status :no_content
            end
          end
        end
      end
    end
  end
end
