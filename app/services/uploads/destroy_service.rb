# frozen_string_literal: true

module Uploads
  class DestroyService < BaseService
    attr_accessor :model, :current_user

    def initialize(model, user = nil)
      @model = model
      @current_user = user
    end

    def execute(secret, filename)
      upload = find_upload(secret, filename)

      unless current_user && upload && current_user.can?(:destroy_upload, upload)
        return error(_("The resource that you are attempting to access does not "\
                       "exist or you don't have permission to perform this action."))
      end

      if upload.destroy
        success(upload: upload)
      else
        error(_('Upload could not be deleted.'))
      end
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def find_upload(secret, filename)
      uploader = uploader_class.new(model, secret: secret)
      upload_paths = uploader.upload_paths(filename)

      Upload.find_by(model: model, uploader: uploader_class.to_s, path: upload_paths)
    rescue FileUploader::InvalidSecret
      nil
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def uploader_class
      case model
      when Group
        NamespaceFileUploader
      when Project
        FileUploader
      else
        raise ArgumentError, "unknown uploader for #{model.class.name}"
      end
    end
  end
end
