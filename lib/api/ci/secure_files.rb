# frozen_string_literal: true

module API
  module Ci
    class SecureFiles < ::API::Base
      include PaginationParams

      before do
        authenticate!
        feature_flag_enabled?
        authorize! :read_secure_files, user_project
      end

      feature_category :pipeline_authoring

      default_format :json

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end

      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'List all Secure Files for a Project'
        params do
          use :pagination
        end
        route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: true
        get ':id/secure_files' do
          secure_files = user_project.secure_files.order_by_created_at
          present paginate(secure_files), with: Entities::Ci::SecureFile
        end

        desc 'Get an individual Secure File'
        params do
          requires :id, type: Integer, desc: 'The Secure File ID'
        end

        route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: true
        get ':id/secure_files/:secure_file_id' do
          secure_file = user_project.secure_files.find(params[:secure_file_id])
          present secure_file, with: Entities::Ci::SecureFile
        end

        desc 'Download a Secure File'
        route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: true
        get ':id/secure_files/:secure_file_id/download' do
          secure_file = user_project.secure_files.find(params[:secure_file_id])

          content_type 'application/octet-stream'
          env['api.format'] = :binary
          header['Content-Disposition'] = "attachment; filename=#{secure_file.name}"
          body secure_file.file.read
        end

        resource do
          before do
            read_only_feature_flag_enabled?
            authorize! :admin_secure_files, user_project
          end

          desc 'Upload a Secure File'
          params do
            requires :name, type: String, desc: 'The name of the file'
            requires :file, types: [Rack::Multipart::UploadedFile, ::API::Validations::Types::WorkhorseFile], desc: 'The secure file to be uploaded', documentation: { type: 'file' }
          end
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: true
          post ':id/secure_files' do
            secure_file = user_project.secure_files.new(
              name: Gitlab::Utils.check_path_traversal!(params[:name])
            )

            secure_file.file = params[:file]

            file_too_large! unless secure_file.file.size < ::Ci::SecureFile::FILE_SIZE_LIMIT.to_i

            if secure_file.save
              if Feature.enabled?(:secure_files_metadata_parsers, user_project)
                ::Ci::ParseSecureFileMetadataWorker.perform_async(secure_file.id) # rubocop:disable CodeReuse/Worker
              end

              present secure_file, with: Entities::Ci::SecureFile
            else
              render_validation_error!(secure_file)
            end
          end

          desc 'Delete an individual Secure File'
          route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: true
          delete ':id/secure_files/:secure_file_id' do
            secure_file = user_project.secure_files.find(params[:secure_file_id])

            ::Ci::DestroySecureFileService.new(user_project, current_user).execute(secure_file)

            no_content!
          end
        end
      end

      helpers do
        def feature_flag_enabled?
          service_unavailable! unless Feature.enabled?(:ci_secure_files, user_project)
        end

        def read_only_feature_flag_enabled?
          service_unavailable! if Feature.enabled?(:ci_secure_files_read_only, user_project, type: :ops)
        end
      end
    end
  end
end
