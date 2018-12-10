# frozen_string_literal: true

# Mounted uploaders are destroyed by carrierwave's after_commit
# hook. This hook fetches upload location (local vs remote) from
# Upload model. So it's necessary to make sure that during that
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
  include FastDestroyAll::Helpers
  include FeatureGate

  # Currently there is no simple way how to select only not-mounted
  # uploads, it should be all FileUploaders so we select them by
  # `uploader` class
  FILE_UPLOADERS = %w(PersonalFileUploader NamespaceFileUploader FileUploader).freeze

  included do
    has_many :uploads, as: :model
    has_many :file_uploads, -> { where(uploader: FILE_UPLOADERS) }, class_name: 'Upload', as: :model

    # TODO: when feature flag is removed, we can use just dependent: destroy
    # option on :file_uploads
    before_destroy :remove_file_uploads

    use_fast_destroy :file_uploads, if: :fast_destroy_enabled?
  end

  def retrieve_upload(_identifier, paths)
    uploads.find_by(path: paths)
  end

  private

  # mounted uploads are deleted in carrierwave's after_commit hook,
  # but FileUploaders which are not mounted must be deleted explicitly and
  # it can not be done in after_commit because FileUploader requires loads
  # associated model on destroy (which is already deleted in after_commit)
  def remove_file_uploads
    fast_destroy_enabled? ? delete_uploads : destroy_uploads
  end

  def delete_uploads
    file_uploads.delete_all(:delete_all)
  end

  def destroy_uploads
    file_uploads.find_each do |upload|
      upload.destroy
    end
  end

  def fast_destroy_enabled?
    Feature.enabled?(:fast_destroy_uploads, self)
  end
end
