# frozen_string_literal: true

require_dependency 'api/validations/validators/limit'

module API
  module Terraform
    class State < ::API::Base
      include ::Gitlab::Utils::StrongMemoize

      feature_category :infrastructure_as_code

      default_format :json

      before do
        authenticate!
        authorize! :read_terraform_state, user_project

        increment_unique_values('p_terraform_state_api_unique_users', current_user.id)
      end

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end

      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        namespace ':id/terraform/state/:name' do
          params do
            requires :name, type: String, desc: 'The name of a Terraform state'
            optional :ID, type: String, limit: 255, desc: 'Terraform state lock ID'
          end

          helpers do
            def remote_state_handler
              ::Terraform::RemoteStateHandler.new(user_project, current_user, name: params[:name], lock_id: params[:ID])
            end
          end

          desc 'Get a terraform state by its name'
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
          get do
            remote_state_handler.find_with_lock do |state|
              no_content! unless state.latest_file && state.latest_file.exists?

              env['api.format'] = :binary # this bypasses json serialization
              body state.latest_file.read
            end
          end

          desc 'Add a new terraform state or update an existing one'
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
          post do
            authorize! :admin_terraform_state, user_project

            data = request.body.read
            no_content! if data.empty?

            remote_state_handler.handle_with_lock do |state|
              state.update_file!(CarrierWaveStringFile.new(data), version: params[:serial], build: current_authenticated_job)
            end

            body false
            status :ok
          end

          desc 'Delete a terraform state of a certain name'
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
          delete do
            authorize! :admin_terraform_state, user_project

            remote_state_handler.handle_with_lock do |state|
              state.destroy!
            end

            body false
            status :ok
          end

          desc 'Lock a terraform state of a certain name'
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
          params do
            requires :ID, type: String, limit: 255, desc: 'Terraform state lock ID'
            requires :Operation, type: String, desc: 'Terraform operation'
            requires :Info, type: String, desc: 'Terraform info'
            requires :Who, type: String, desc: 'Terraform state lock owner'
            requires :Version, type: String, desc: 'Terraform version'
            requires :Created, type: String, desc: 'Terraform state lock timestamp'
            requires :Path, type: String, desc: 'Terraform path'
          end
          post '/lock' do
            authorize! :admin_terraform_state, user_project

            status_code = :ok
            lock_info = {
              'Operation' => params[:Operation],
              'Info' => params[:Info],
              'Version' => params[:Version],
              'Path' => params[:Path]
            }

            begin
              remote_state_handler.lock!
            rescue ::Terraform::RemoteStateHandler::StateLockedError
              status_code = :conflict
            end

            remote_state_handler.find_with_lock do |state|
              lock_info['ID'] = state.lock_xid
              lock_info['Who'] = state.locked_by_user.username
              lock_info['Created'] = state.locked_at

              env['api.format'] = :binary # this bypasses json serialization
              body lock_info.to_json
              status status_code
            end
          end

          desc 'Unlock a terraform state of a certain name'
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
          params do
            optional :ID, type: String, limit: 255, desc: 'Terraform state lock ID'
          end
          delete '/lock' do
            authorize! :admin_terraform_state, user_project

            remote_state_handler.unlock!
            status :ok
          rescue ::Terraform::RemoteStateHandler::StateLockedError
            status :conflict
          end
        end
      end
    end
  end
end
