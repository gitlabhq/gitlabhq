class GeoNodeStatus
  include ActiveModel::Model

  attr_accessor :id
  attr_writer :health

  def health
    @health ||= HealthCheck::Utils.process_checks(['geo'])
  end

  def healthy?
    health.blank?
  end

  def repositories_count
    @repositories_count ||= Project.count
  end

  def repositories_count=(value)
    @repositories_count = value.to_i
  end

  def repositories_synced_count
    @repositories_synced_count ||= Geo::ProjectRegistry.synced.count
  end

  def repositories_synced_count=(value)
    @repositories_synced_count = value.to_i
  end

  def repositories_synced_in_percentage
    sync_percentage(repositories_count, repositories_synced_count)
  end

  def repositories_failed_count
    @repositories_failed_count ||= Geo::ProjectRegistry.failed.count
  end

  def repositories_failed_count=(value)
    @repositories_failed_count = value.to_i
  end

  def lfs_objects_count
    @lfs_objects_count ||= LfsObject.count
  end

  def lfs_objects_count=(value)
    @lfs_objects_count = value.to_i
  end

  def lfs_objects_synced_count
    @lfs_objects_synced_count ||= Geo::FileRegistry.where(file_type: :lfs).count
  end

  def lfs_objects_synced_count=(value)
    @lfs_objects_synced_count = value.to_i
  end

  def lfs_objects_synced_in_percentage
    sync_percentage(lfs_objects_count, lfs_objects_synced_count)
  end

  def attachments_count
    @attachments_count ||= Upload.count
  end

  def attachments_count=(value)
    @attachments_count = value.to_i
  end

  def attachments_synced_count
    @attachments_synced_count ||= begin
      upload_ids = Upload.pluck(:id)
      synced_ids = Geo::FileRegistry.where(file_type: [:attachment, :avatar, :file]).pluck(:file_id)

      (synced_ids & upload_ids).length
    end
  end

  def attachments_synced_count=(value)
    @attachments_synced_count = value.to_i
  end

  def attachments_synced_in_percentage
    sync_percentage(attachments_count, attachments_synced_count)
  end

  private

  def sync_percentage(total, synced)
    return 0 if total.zero?

    (synced.to_f / total.to_f) * 100.0
  end
end
