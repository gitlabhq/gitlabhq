# frozen_string_literal: true

module DesignManagement
  # This Uploader is used to generate and serve the smaller versions of
  # the design files.
  #
  # The original (full-sized) design files are stored in Git LFS, and so
  # have a different uploader, `LfsObjectUploader`.
  class DesignV432x230Uploader < GitlabUploader
    include CarrierWave::MiniMagick
    include RecordsUploads::Concern
    include ObjectStorage::Concern
    prepend ObjectStorage::Extension::RecordsUploads

    # We choose not to resize `image/ico` as we assume there will be no
    # benefit in generating an 432x230 sized icon.
    #
    # We currently cannot resize `image/tiff`.
    # See https://gitlab.com/gitlab-org/gitlab/issues/207740
    #
    # We currently choose not to resize `image/svg+xml` for security reasons.
    # See https://gitlab.com/gitlab-org/gitlab/issues/207740#note_302766171
    MIME_TYPE_ALLOWLIST = %w[image/png image/jpeg image/bmp image/gif].freeze

    process resize_to_fit: [432, 230]

    # Allow CarrierWave to reject files without correct mimetypes.
    def content_type_whitelist
      MIME_TYPE_ALLOWLIST
    end

    # Override `GitlabUploader` and always return false, otherwise local
    # `LfsObject` files would be deleted.
    # https://github.com/carrierwaveuploader/carrierwave/blob/f84672a/lib/carrierwave/uploader/cache.rb#L131-L135
    def move_to_cache
      false
    end

    private

    def dynamic_segment
      File.join(model.class.underscore, mounted_as.to_s, model.id.to_s)
    end
  end
end
