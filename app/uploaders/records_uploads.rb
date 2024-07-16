# frozen_string_literal: true

module RecordsUploads
  module Concern
    extend ActiveSupport::Concern

    # This value is stored in `uploads.version`. Increment this value to have
    # functionality that only applies to certain versions of uploads.
    VERSION = 2

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
    # rubocop: disable CodeReuse/ActiveRecord
    def record_upload(_tempfile = nil)
      return unless model
      return unless file && file.exists?

      Upload.transaction { readd_upload }
    end

    def readd_upload
      Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.temporary_ignore_tables_in_transaction(
        %w[uploads], url: "https://gitlab.com/gitlab-org/gitlab/-/issues/398199"
      ) do
        uploads.where(model: model, path: upload_path).delete_all
        upload.delete if upload

        self.upload = build_upload.tap(&:save!)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def upload_path
      File.join(store_dir, filename.to_s)
    end

    def filename
      upload&.path ? File.basename(upload.path) : super
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def uploads
      Upload.order(id: :desc).where(uploader: self.class.to_s)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def build_upload
      Upload.new(
        uploader: self.class.to_s,
        size: file.size,
        path: upload_path,
        model: model,
        mount_point: mounted_as,
        version: VERSION
      )
    end

    # Before removing an attachment, destroy any Upload records at the same path
    #
    # Called `before :remove`
    # rubocop: disable CodeReuse/ActiveRecord
    def destroy_upload(*args)
      return unless file && file.exists?

      self.upload = nil
      uploads.where(path: upload_path).delete_all
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
