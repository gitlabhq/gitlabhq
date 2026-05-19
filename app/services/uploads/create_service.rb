# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- Uploads is an existing service namespace, see Uploads::DestroyService
module Uploads
  class CreateService
    include Gitlab::Routing

    def initialize(parent, user, file:)
      @parent = parent
      @current_user = user
      @file = file
    end

    def execute
      uploader_class = parent.is_a?(Group) ? NamespaceFileUploader : FileUploader
      uploader = UploadService.new(parent, file, uploader_class, uploaded_by_user_id: current_user.id).execute

      if uploader
        ServiceResponse.success(payload: build_response(uploader))
      else
        ServiceResponse.error(message: _('Failed to upload file.'), payload: empty_response)
      end
    end

    private

    attr_reader :parent, :current_user, :file

    def build_response(uploader)
      model_type = parent.is_a?(Group) ? 'group' : 'project'

      {
        upload: uploader.upload,
        markdown: uploader.markdown_link,
        url: uploader.to_h[:url],
        alt: uploader.to_h[:alt],
        full_path: banzai_upload_path(model_type, parent.id, uploader.secret, uploader.filename)
      }
    end

    def empty_response
      {
        upload: nil,
        markdown: nil,
        url: nil,
        alt: nil,
        full_path: nil
      }
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
