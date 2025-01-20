# frozen_string_literal: true

module API
  module Ci
    class SecureFiles < ::API::Base
      include PaginationParams

      before do
        check_api_enabled!
        authenticate!
        authorize! :read_secure_files, user_project
      end

      feature_category :mobile_devops

      default_format :json

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project owned by the
        authenticated user'
      end

      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Get list of secure files in a project' do
          success Entities::Ci::SecureFile
          tags %w[secure_files]
        end
        params do
          use :pagination
        end
        route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_secure_files
        get ':id/secure_files' do
          secure_files = user_project.secure_files.order_by_created_at
          present paginate(secure_files), with: Entities::Ci::SecureFile
        end

        desc 'Get the details of a specific secure file in a project' do
          success Entities::Ci::SecureFile
          tags %w[secure_files]
          failure [{ code: 404, message: '404 Not found' }]
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a secure file'
        end

        route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_secure_files
        get ':id/secure_files/:secure_file_id' do
          secure_file = user_project.secure_files.find(params[:secure_file_id])
          present secure_file, with: Entities::Ci::SecureFile
        end

        desc 'Download secure file' do
          failure [{ code: 404, message: '404 Not found' }]
          tags %w[secure_files]
        end
        route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_secure_files
        get ':id/secure_files/:secure_file_id/download' do
          secure_file = user_project.secure_files.find(params[:secure_file_id])

          content_type 'application/octet-stream'
          env['api.format'] = :binary
          header['Content-Disposition'] = "attachment; filename=#{secure_file.name}"
          body secure_file.file.read
        end

        resource do
          before do
            authorize! :admin_secure_files, user_project
          end

          desc 'Create a secure file' do
            success Entities::Ci::SecureFile
            tags %w[secure_files]
            failure [{ code: 400, message: '400 Bad Request' }]
          end
          params do
            requires :name, type: String, desc: 'The name of the file being uploaded. The filename must be unique within
            the project'
            requires :file, types: [Rack::Multipart::UploadedFile, ::API::Validations::Types::WorkhorseFile], desc: 'The secure file being uploaded', documentation: { type: 'file' }
          end
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: true
          route_setting :authorization, job_token_policies: :admin_secure_files
          post ':id/secure_files' do
            secure_file = user_project.secure_files.new(
              name: Gitlab::PathTraversal.check_path_traversal!(params[:name])
            )

            secure_file.file = params[:file]

            file_too_large! unless secure_file.file.size < ::Ci::SecureFile::FILE_SIZE_LIMIT.to_i

            if secure_file.save
              ::Ci::ParseSecureFileMetadataWorker.perform_async(secure_file.id) # rubocop:disable CodeReuse/Worker
              present secure_file, with: Entities::Ci::SecureFile
            else
              render_validation_error!(secure_file)
            end
          end

          desc 'Remove a secure file' do
            tags %w[secure_files]
            failure [{ code: 404, message: '404 Not found' }]
          end
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: true
          route_setting :authorization, job_token_policies: :admin_secure_files
          delete ':id/secure_files/:secure_file_id' do
            secure_file = user_project.secure_files.find(params[:secure_file_id])

            ::Ci::DestroySecureFileService.new(user_project, current_user).execute(secure_file)

            no_content!
          end
        end
      end

      helpers do
        def check_api_enabled!
          forbidden! unless Gitlab.config.ci_secure_files.enabled
        end
      end
    end
  end
end
