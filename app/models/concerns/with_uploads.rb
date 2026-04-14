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

    # NOTE:
    #
    # The uploads table is partitioned by model_type and has FK constraints
    # on sharding key columns (namespace_id, project_id, organization_id)
    # that reference their parent tables with ON DELETE CASCADE. When a
    # model (e.g., Project, Group, User) is destroyed, PostgreSQL cascade-
    # deletes the associated Upload rows inside the same transaction,
    # before carrierwave's after_commit hook fires. Since Rails also
    # freezes the model after destroy, carrierwave cannot look up the
    # mounter or the upload record to find the remote file path.
    #
    # The capture_mounted_remote_uploaders callback runs before_destroy to
    # snapshot any remote mounted uploaders while the Upload rows still
    # exist. It then schedules remote file deletion in an after_commit
    # hook, ensuring object storage files are cleaned up.
    #
    # This only matters for sharding keys with ON DELETE CASCADE. The
    # uploaded_by_user_id FK uses ON DELETE SET NULL, so the Upload row
    # survives the user's deletion and carrierwave's normal after_commit
    # cleanup path works without intervention.
    before_destroy :capture_mounted_remote_uploaders, prepend: true
  end

  def retrieve_upload(_identifier, paths)
    uploads.find_by(path: paths)
  end

  private

  def capture_mounted_remote_uploaders
    return unless uploads_cascade_deleted_on_destroy?

    mounted_remote_uploaders = uploads.where.not(uploader: FILE_UPLOADERS).filter_map do |upload|
      next unless upload.store == ObjectStorage::Store::REMOTE

      upload.retrieve_uploader(upload.read_attribute(:mount_point)&.to_sym)
    end

    return if mounted_remote_uploaders.empty?

    run_after_commit do
      mounted_remote_uploaders.each do |uploader|
        uploader.file&.delete
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e)
      end
    end
  end

  def uploads_cascade_deleted_on_destroy?
    sharding_key = try(:uploads_sharding_key)
    return false unless sharding_key.present?

    (sharding_key.keys & %i[namespace_id project_id organization_id]).any?
  end
end
