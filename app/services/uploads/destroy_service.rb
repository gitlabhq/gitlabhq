# frozen_string_literal: true

module Uploads
  class DestroyService < BaseService
    attr_accessor :model, :current_user

    def initialize(model, user = nil)
      @model = model
      @current_user = user
    end

    def execute(upload)
      unless current_user && upload && current_user.can?(:destroy_upload, upload)
        return error(_("The resource that you are attempting to access does not " \
                       "exist or you don't have permission to perform this action."))
      end

      if upload.destroy
        success(upload: upload)
      else
        error(_('Upload could not be deleted.'))
      end
    end
  end
end
