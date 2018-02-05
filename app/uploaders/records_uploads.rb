module RecordsUploads
  module Concern
    extend ActiveSupport::Concern

    attr_accessor :upload

    included do
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

      Upload.transaction do
        uploads.where(path: upload_path).delete_all
        upload.destroy! if upload

        self.upload = build_upload
        upload.save!
      end
    end

    def upload_path
      File.join(store_dir, filename.to_s)
    end

    private

    def uploads
      Upload.order(id: :desc).where(uploader: self.class.to_s)
    end

    def build_upload
      Upload.new(
        uploader: self.class.to_s,
        size: file.size,
        path: upload_path,
        model: model,
        mount_point: mounted_as
      )
    end

    # Before removing an attachment, destroy any Upload records at the same path
    #
    # Called `before :remove`
    def destroy_upload(*args)
      return unless file && file.exists?

      self.upload = nil
      uploads.where(path: upload_path).delete_all
    end
  end
end
