# Mounted uploaders are destroyed by carrierwave's after_commit
# hook. This hook fetches upload location (local vs remote) from
# Upload model. So it's neccessary to make sure that during that
# after_commit hook model's associated uploads are not deleted yet.
# IOW we can not use dependent: :destroy :
# has_many :uploads, as: :model, dependent: :destroy
#
# And because not-mounted uploads require presence of upload's
# object model when destroying them (FileUploader's `build_upload` method
# references `model` on delete), we can not use after_commit hook for these
# uploads.
#
# Instead FileUploads are destroyed in before_destroy hook and remaining uploads
# are destroyed by the carrierwave's after_commit hook.

module WithUploads
  extend ActiveSupport::Concern

  # Currently there is no simple way how to select only not-mounted
  # uploads, it should be all FileUploaders so we select them by
  # `uploader` class
  FILE_UPLOADERS = %w(PersonalFileUploader NamespaceFileUploader FileUploader).freeze

  included do
    has_many :uploads, as: :model

    before_destroy :destroy_file_uploads
  end

  # mounted uploads are deleted in carrierwave's after_commit hook,
  # but FileUploaders which are not mounted must be deleted explicitly and
  # it can not be done in after_commit because FileUploader requires loads
  # associated model on destroy (which is already deleted in after_commit)
  def destroy_file_uploads
    self.uploads.where(uploader: FILE_UPLOADERS).find_each do |upload|
      upload.destroy
    end
  end

  def retrieve_upload(_identifier, paths)
    uploads.find_by(path: paths)
  end
end
