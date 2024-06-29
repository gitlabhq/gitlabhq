# frozen_string_literal: true

module API
  class MarkdownUploads < ::API::Base
    feature_category :team_planning

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Workhorse authorize the file upload' do
        detail 'This feature was introduced in GitLab 13.11'
        success code: 200
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[projects]
      end
      post ':id/uploads/authorize' do
        require_gitlab_workhorse!

        status 200
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE
        FileUploader.workhorse_authorize(has_length: false, maximum_size: user_project.max_attachment_size)
      end

      desc 'Upload a file' do
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
      post ':id/uploads' do
        upload = UploadService.new(user_project, params[:file]).execute

        present upload, with: Entities::ProjectUpload
      end
    end
  end
end
