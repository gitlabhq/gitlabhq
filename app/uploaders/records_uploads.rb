module RecordsUploads
  extend ActiveSupport::Concern

  included do
    after :store,   :record_upload
    before :remove, :destroy_upload
  end

  private

  # After storing an attachment, create a corresponding Upload record
  #
  # NOTE: We're ignoring the argument passed to this callback because we want
  # the `SanitizedFile` object from `CarrierWave::Uploader::Base#file`, not the
  # `Tempfile` object the callback gets.
  #
  # Called `after :store`
  def record_upload(_tempfile)
    return unless local_file?
    return unless file.exists?

    Upload.record(self)
  end

  # Before removing an attachment, destroy any Upload records at the same path
  #
  # Called `before :remove`
  def destroy_upload(*args)
    return unless local_file?
    return unless file

    Upload.remove_path(relative_path)
  end
end
