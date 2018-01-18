module RecordsUploads
  module Concern
    extend ActiveSupport::Concern

    attr_accessor :upload

    included do
      before :store,  :destroy_previous_upload
      after  :store,  :record_upload
      before :remove, :destroy_upload
    end

    # After storing an attachment, create a corresponding Upload record
    #
    # NOTE: We're ignoring the argument passed to this callback because we want
    # the `SanitizedFile` object from `CarrierWave::Uploader::Base#file`, not the
    # `Tempfile` object the callback gets.
    #
    # Called `after :store`
    def record_upload(_tempfile = nil)
      return unless model
      return unless file && file.exists?

      Upload.create(
        size: file.size,
        path: upload_path,
        model: model,
        uploader: self.class.to_s
      )
    end

    def upload_path
      File.join(store_dir, filename.to_s)
    end

    private

    def destroy_previous_upload(*args)
      return unless upload

      upload.destroy!
    end

    # Before removing an attachment, destroy any Upload records at the same path
    #
    # Called `before :remove`
    def destroy_upload(*args)
      return unless file && file.exists?

      # that should be the old path?
      Upload.remove_path(upload_path)
    end
  end
end
