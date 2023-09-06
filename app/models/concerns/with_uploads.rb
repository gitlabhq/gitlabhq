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

  # Currently there is no simple way how to select only not-mounted
  # uploads, it should be all FileUploaders so we select them by
  # `uploader` class
  FILE_UPLOADERS = %w[PersonalFileUploader NamespaceFileUploader FileUploader].freeze

  included do
    around_destroy :ignore_uploads_table_in_transaction

    def ignore_uploads_table_in_transaction(&blk)
      Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.temporary_ignore_tables_in_transaction(
        %w[uploads], url: "https://gitlab.com/gitlab-org/gitlab/-/issues/398199", &blk)
    end

    has_many :uploads, as: :model
    has_many :file_uploads, -> { where(uploader: FILE_UPLOADERS) },
      class_name: 'Upload', as: :model,
      dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

    use_fast_destroy :file_uploads
  end

  def retrieve_upload(_identifier, paths)
    uploads.find_by(path: paths)
  end
end
