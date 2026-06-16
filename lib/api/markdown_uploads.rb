# frozen_string_literal: true

module API
  class MarkdownUploads < ::API::Base
    include PaginationParams
    include APIGuard

    feature_category :team_planning

    FILENAME_QUERY_PARAM_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(
      filename: API::NO_SLASH_URL_PART_REGEX
    )

    allow_access_with_scope :ai_workflows, if: ->(request) { request.post? }

    before { authenticate_non_get! }

    helpers do
      def find_uploads(parent)
        uploads = Banzai::UploadsFinder.new(parent: parent).execute
        uploads.preload_uploaded_by_user
      end

      def find_upload(parent, upload_id: nil, secret: nil, filename: nil)
        finder = Banzai::UploadsFinder.new(parent: parent)

        if upload_id
          finder.find(upload_id)
        else
          finder.find_by_secret_and_filename(secret, filename)
        end
      end
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Workhorse authorize the file upload' do
        detail 'This feature was introduced in GitLab 13.11'
        success code: 200
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[projects]
      end
      route_setting :authorization, skip_granular_token_authorization: :workhorse_pre_authorization
      post ':id/uploads/authorize' do
        require_gitlab_workhorse!

        status 200
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE
        FileUploader.workhorse_authorize(has_length: false, maximum_size: user_project.max_attachment_size)
      end

      desc 'Create an upload' do
        detail 'Creates an upload.'
        success code: 201, model: Entities::ProjectUpload
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[projects]
      end
      params do
        requires :file, types: [Rack::Multipart::UploadedFile, ::API::Validations::Types::WorkhorseFile],
          desc: 'The attachment file to be uploaded', documentation: { type: 'file' }
      end
      route_setting :authorization, permissions: :create_markdown_upload, boundary_type: :project
      post ':id/uploads' do
        upload = UploadService.new(user_project, params[:file], uploaded_by_user_id: current_user.id).execute

        present upload, with: Entities::ProjectUpload
      end

      desc 'List all uploads' do
        detail 'Lists all uploads of a project sorted by `created_at` in descending order. You must have the ' \
          'Maintainer or Owner role for the project.'
        success code: 200, model: Entities::MarkdownUploadAdmin
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        is_array true
        tags %w[projects]
      end
      params do
        use :pagination
      end
      route_setting :authorization, permissions: :read_markdown_upload, boundary_type: :project
      get ':id/uploads' do
        authorize! :admin_upload, user_project

        uploads = find_uploads(user_project)

        present paginate(uploads), with: Entities::MarkdownUploadAdmin
      end

      desc 'Download an uploaded file by ID' do
        detail 'Downloads an uploaded file by ID. You must have the Maintainer or Owner role for the project.'
        success File
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[projects]
      end
      params do
        requires :upload_id, type: Integer, desc: 'The ID of a project upload'
      end
      route_setting :authorization, permissions: :read_markdown_upload, boundary_type: :project
      get ':id/uploads/:upload_id' do
        # Fetching uploads by ID is maintainer-only because it can be used to enumerate uploads
        # even without the secret
        authorize! :admin_upload, user_project

        upload = find_upload(user_project, upload_id: params[:upload_id])

        present_carrierwave_file!(upload.retrieve_uploader)
      end

      desc 'Download an uploaded file by secret and filename' do
        detail 'Downloads an uploaded file by secret and filename.'
        success File
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[projects]
      end
      params do
        requires :secret, type: String, desc: 'The 32-character secret of a project upload'
        requires :filename, type: String, file_path: true, desc: 'The filename of a project upload'
      end
      route_setting :authorization, permissions: :read_markdown_upload, boundary_type: :project
      get ':id/uploads/:secret/:filename', requirements: FILENAME_QUERY_PARAM_REQUIREMENTS do
        authorize! :read_upload, user_project

        upload = find_upload(user_project, secret: params[:secret], filename: params[:filename])

        present_carrierwave_file!(upload&.retrieve_uploader)
      end

      desc 'Delete an uploaded file by ID' do
        detail 'Deletes an uploaded file by ID. You must have the Maintainer or Owner role for the project.'
        success code: 204
        failure [
          { code: 400, message: 'Bad request' },
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[projects]
      end
      params do
        requires :upload_id, type: Integer, desc: 'The ID of a project upload'
      end
      route_setting :authorization, permissions: :delete_markdown_upload, boundary_type: :project
      delete ':id/uploads/:upload_id' do
        authorize! :destroy_upload, user_project

        upload = find_upload(user_project, upload_id: params[:upload_id])
        result = Uploads::DestroyService.new(user_project, current_user).execute(upload)

        if result[:status] == :success
          status 204
        else
          bad_request!(result[:message])
        end
      end

      desc 'Delete an uploaded file by secret and filename' do
        detail 'Deletes an uploaded file by secret and filename. You must have the Maintainer or Owner role for the ' \
          'project.'
        success code: 204
        failure [
          { code: 400, message: 'Bad request' },
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[projects]
      end
      params do
        requires :secret, type: String, desc: 'The 32-character secret of a project upload'
        requires :filename, type: String, file_path: true, desc: 'The filename of a project upload'
      end
      route_setting :authorization, permissions: :delete_markdown_upload, boundary_type: :project
      delete ':id/uploads/:secret/:filename', requirements: FILENAME_QUERY_PARAM_REQUIREMENTS do
        authorize! :destroy_upload, user_project

        upload = find_upload(user_project, secret: params[:secret], filename: params[:filename])
        result = Uploads::DestroyService.new(user_project, current_user).execute(upload)

        if result[:status] == :success
          status 204
        else
          bad_request!(result[:message])
        end
      end
    end

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Workhorse authorize the file upload' do
        detail 'This feature was introduced in GitLab 19.0'
        success code: 200
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[groups]
      end
      route_setting :authorization, skip_granular_token_authorization: :workhorse_pre_authorization
      post ':id/uploads/authorize' do
        not_found! unless Feature.enabled?(:group_uploads_api, user_group)

        require_gitlab_workhorse!

        status 200
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE
        NamespaceFileUploader.workhorse_authorize(
          has_length: false,
          maximum_size: Gitlab::CurrentSettings.max_attachment_size.megabytes.to_i
        )
      end

      desc 'Upload a file to a group' do
        detail 'Uploads a file to the specified group. Returns a markdown-formatted link to the file.'
        success code: 201, model: Entities::GroupUpload
        failure [
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[groups]
      end
      params do
        requires :file, types: [Rack::Multipart::UploadedFile, ::API::Validations::Types::WorkhorseFile],
          desc: 'The file to upload', documentation: { type: 'file' }
      end
      route_setting :authorization, permissions: :create_markdown_upload, boundary_type: :group
      post ':id/uploads' do
        not_found! unless Feature.enabled?(:group_uploads_api, user_group)

        upload = UploadService.new(user_group, params[:file], NamespaceFileUploader,
          uploaded_by_user_id: current_user.id).execute

        bad_request!('Failed to upload file') unless upload

        present upload, with: Entities::GroupUpload
      end

      desc 'List all uploads for a group' do
        detail 'Lists all uploads for a specified group sorted by `created_at` in descending order. You must have ' \
          'the Maintainer or Owner role for the group.'
        success code: 200, model: Entities::MarkdownUploadAdmin
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        is_array true
        tags %w[groups]
      end
      params do
        use :pagination
      end
      route_setting :authorization, permissions: :read_markdown_upload, boundary_type: :group
      get ':id/uploads' do
        authorize! :admin_upload, user_group

        uploads = find_uploads(user_group)

        present paginate(uploads), with: Entities::MarkdownUploadAdmin
      end

      desc 'Download an uploaded file by ID' do
        detail 'Downloads an uploaded file with a specified ID. You must have the Maintainer or Owner role for the ' \
          'group.'
        success File
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[groups]
      end
      params do
        requires :upload_id, type: Integer, desc: 'The ID of a group upload'
      end
      route_setting :authorization, permissions: :read_markdown_upload, boundary_type: :group
      get ':id/uploads/:upload_id' do
        # Fetching uploads by ID is maintainer-only because it can be used to enumerate uploads
        # even without the secret
        authorize! :admin_upload, user_group

        upload = find_upload(user_group, upload_id: params[:upload_id])

        present_carrierwave_file!(upload.retrieve_uploader)
      end

      desc 'Download an uploaded file by secret and filename' do
        detail 'Downloads an uploaded file with a specified secret and filename. You must have the Guest, Planner, ' \
          'Reporter, Developer, Maintainer, or Owner role for the group.'
        success File
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[groups]
      end
      params do
        requires :secret, type: String, desc: 'The 32-character secret of a group upload'
        requires :filename, type: String, file_path: true, desc: 'The filename of a group upload'
      end
      route_setting :authorization, permissions: :read_markdown_upload, boundary_type: :group
      get ':id/uploads/:secret/:filename', requirements: FILENAME_QUERY_PARAM_REQUIREMENTS do
        authorize! :read_upload, user_group

        upload = find_upload(user_group, secret: params[:secret], filename: params[:filename])

        present_carrierwave_file!(upload&.retrieve_uploader)
      end

      desc 'Delete an uploaded file by ID' do
        detail 'Deletes an uploaded file with a specified ID. You must have the Maintainer or Owner role for the ' \
          'group.'
        success code: 204
        failure [
          { code: 400, message: 'Bad request' },
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[groups]
      end
      params do
        requires :upload_id, type: Integer, desc: 'The ID of a group upload'
      end
      route_setting :authorization, permissions: :delete_markdown_upload, boundary_type: :group
      delete ':id/uploads/:upload_id' do
        authorize! :destroy_upload, user_group

        upload = find_upload(user_group, upload_id: params[:upload_id])
        result = Uploads::DestroyService.new(user_group, current_user).execute(upload)

        if result[:status] == :success
          status 204
        else
          bad_request!(result[:message])
        end
      end

      desc 'Delete an uploaded file by secret and filename' do
        detail 'Deletes an uploaded file with a specified secret and filename. You must have the Maintainer or Owner ' \
          'role for the group.'
        success code: 204
        failure [
          { code: 400, message: 'Bad request' },
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[groups]
      end
      params do
        requires :secret, type: String, desc: 'The 32-character secret of a group upload'
        requires :filename, type: String, file_path: true, desc: 'The filename of a group upload'
      end
      route_setting :authorization, permissions: :delete_markdown_upload, boundary_type: :group
      delete ':id/uploads/:secret/:filename', requirements: FILENAME_QUERY_PARAM_REQUIREMENTS do
        authorize! :destroy_upload, user_group

        upload = find_upload(user_group, secret: params[:secret], filename: params[:filename])
        result = Uploads::DestroyService.new(user_group, current_user).execute(upload)

        if result[:status] == :success
          status 204
        else
          bad_request!(result[:message])
        end
      end
    end
  end
end
