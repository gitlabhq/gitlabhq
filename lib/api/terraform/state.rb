# frozen_string_literal: true

module API
  module Terraform
    class State < ::API::Base
      include ::Gitlab::Utils::StrongMemoize

      feature_category :infrastructure_as_code
      urgency :low

      default_format :json

      rescue_from(
        ::Terraform::RemoteStateHandler::StateDeletedError,
        ::ActiveRecord::RecordNotUnique,
        ::PG::UniqueViolation
      ) do |e|
        render_api_error!(e.message, 422)
      end

      STATE_NAME_URI_REQUIREMENTS = { name: API::NO_SLASH_URL_PART_REGEX }.freeze

      before do
        if request.path_info.end_with?('/authorize')
          require_gitlab_workhorse!
          next
        end

        authenticate!
        authorize! :read_terraform_state, user_project

        increment_unique_values('p_terraform_state_api_unique_users', current_user.id)

        Gitlab::Tracking.event(
          'API::Terraform::State',
          'terraform_state_api_request',
          namespace: user_project&.namespace,
          user: current_user,
          project: user_project,
          label: 'redis_hll_counters.terraform.p_terraform_state_api_unique_users_monthly',
          context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll,
            event: 'p_terraform_state_api_unique_users').to_context]
        )
      end

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end

      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        params do
          requires :name, type: String, limit: 255, desc: 'The name of a Terraform state'
        end

        namespace ':id/terraform/state/:name', requirements: STATE_NAME_URI_REQUIREMENTS do
          params do
            optional :ID, type: String, limit: 255, desc: 'Terraform state lock ID'
          end

          helpers do
            def remote_state_handler
              ::Terraform::RemoteStateHandler.new(user_project, current_user, name: params[:name], lock_id: params[:ID])
            end
          end

          desc 'Get a Terraform state by its name' do
            detail 'Get a Terraform state by its name'
            success [
              { code: 200 },
              { code: 204, message: 'Empty state' }
            ]
            failure [
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not found' },
              { code: 422, message: 'Validation failure' }
            ]
            tags %w[terraform_state]
          end
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
          route_setting :authorization, job_token_policies: :read_terraform_state
          get do
            remote_state_handler.find_with_lock do |state|
              no_content! unless state.latest_file && state.latest_file.exists?

              env['api.format'] = :binary # this bypasses json serialization

              if state.latest_version.is_encrypted?
                body state.latest_file.read
              elsif state.latest_file.file_storage?
                sendfile state.latest_file.path
              else
                workhorse_headers = Gitlab::Workhorse.send_url(state.latest_file.url)
                header workhorse_headers[0], workhorse_headers[1]
                body ""
              end
            end
          end

          # POST /:id/terraform/state/:name/authorize'
          desc 'Authorize Terraform state upload' do
            detail 'This feature was introduced in GitLab 18.5'
            success code: 200
            failure [
              { code: 400, message: 'Bad Request' },
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not Found' }
            ]
            tags %w[terraform_state]
          end
          post 'authorize' do
            status 200
            content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE

            max_state_size = Gitlab::CurrentSettings.max_terraform_state_size_bytes
            # Direct upload is not supported, so it doesn't matter what value has_length is,
            # but generally the state should be sent with a Content-Length.
            params = { has_length: true }
            params[:maximum_size] = max_state_size if max_state_size > 0
            ::Terraform::StateUploader.workhorse_authorize(**params)
          end

          desc 'Add a new Terraform state or update an existing one' do
            detail 'Add a new Terraform state or update an existing one'
            success [
              { code: 200 },
              { code: 204, message: 'No data provided' }
            ]
            failure [
              { code: 403, message: 'Forbidden' },
              { code: 422, message: 'Validation failure' },
              { code: 413, message: 'Request Entity Too Large' }
            ]
            tags %w[terraform_state]
          end
          params do
            requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: 'The package file to be published (generated by Multipart middleware)', documentation: { type: 'file' }
          end
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
          route_setting :authorization, job_token_policies: :admin_terraform_state
          post do
            authorize! :admin_terraform_state, user_project

            # Direct upload is not supported, so we should have access to the file.
            file_path = params['file.path']
            unprocessable_entity!('Terraform state file not found on disk') unless File.exist?(file_path)
            data = File.read(file_path)

            no_content! if data.empty?

            # This should have already been limited by Workhorse, but keep here for a sanity check.
            max_state_size = Gitlab::CurrentSettings.max_terraform_state_size_bytes
            file_too_large! if max_state_size > 0 && data.size > max_state_size

            # To reduce CPU and memory, use a streaming parser to extract this.
            serial = ::Gitlab::Terraform::StateParser.extract_serial(data)

            unprocessable_entity!('No serial in payload') unless serial.present?

            remote_state_handler.handle_with_lock do |state|
              state.update_file!(CarrierWaveStringFile.new(data), version: serial, build: current_authenticated_job)
            end

            body false
            status :ok
          rescue ::JSON::ParserError
            unprocessable_entity!('invalid JSON')
          end

          desc 'Delete a Terraform state of a certain name' do
            detail 'Delete a Terraform state of a certain name'
            success code: 200
            failure [
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not found' },
              { code: 422, message: 'Validation failure' }
            ]
            tags %w[terraform_state]
          end
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
          route_setting :authorization, job_token_policies: :admin_terraform_state
          delete do
            authorize! :admin_terraform_state, user_project

            remote_state_handler.find_with_lock do |state|
              ::Terraform::States::TriggerDestroyService.new(state, current_user: current_user).execute
            end

            body false
            status :ok
          end

          desc 'Lock a Terraform state of a certain name' do
            detail 'Lock a Terraform state of a certain name'
            success code: 200
            failure [
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not found' },
              { code: 409, message: 'Conflict' },
              { code: 422, message: 'Validation failure' }
            ]
            tags %w[terraform_state]
          end
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
          route_setting :authorization, job_token_policies: :admin_terraform_state
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

          desc 'Unlock a Terraform state of a certain name' do
            detail 'Unlock a Terraform state of a certain name'
            success code: 200
            failure [
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not found' },
              { code: 409, message: 'Conflict' },
              { code: 422, message: 'Validation failure' }
            ]
            tags %w[terraform_state]
          end
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
          route_setting :authorization, job_token_policies: :admin_terraform_state
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
