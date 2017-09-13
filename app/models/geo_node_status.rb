class GeoNodeStatus
  include ActiveModel::Model

  attr_accessor :id
  attr_writer :health

  def health
    @health ||= HealthCheck::Utils.process_checks(['geo'])
  rescue NotImplementedError => e
    @health = e.to_s
  end

  def healthy?
    health.blank?
  end

  def db_replication_lag
    return @db_replication_lag if defined?(@db_replication_lag)

    @db_replication_lag = Gitlab::Geo::HealthCheck.db_replication_lag if Gitlab::Geo.secondary?
  end

  def db_replication_lag=(value)
    @db_replication_lag = value
  end

  def last_event_id
    @last_event_id ||= latest_event&.id
  end

  def last_event_id=(value)
    @last_event_id = value
  end

  def last_event_date
    @last_event_date ||= Geo::EventLog.latest_event&.created_at
  end

  def last_event_date=(value)
    @last_event_date = value
  end

  def cursor_last_event_id
    return @cursor_last_event_id if defined?(@cursor_last_event_id)

    @cursor_last_event_id = cursor_last_processed&.event_id if Gitlab::Geo.secondary?
  end

  def cursor_last_event_id=(value)
    @cursor_last_event_id = value
  end

  def cursor_last_event_date
    event_id = cursor_last_event_id

    return unless event_id

    @cursor_last_event_date ||= Geo::EventLog.find_by(id: event_id)&.created_at
  end

  def cursor_last_event_date=(value)
    @cursor_last_event_date = value
  end

  def repositories_count
    @repositories_count ||= repositories.count
  end

  def repositories_count=(value)
    @repositories_count = value.to_i
  end

  def repositories_synced_count
    @repositories_synced_count ||= project_registries.synced.count
  end

  def repositories_synced_count=(value)
    @repositories_synced_count = value.to_i
  end

  def repositories_synced_in_percentage
    sync_percentage(repositories_count, repositories_synced_count)
  end

  def repositories_failed_count
    @repositories_failed_count ||= project_registries.failed.count
  end

  def repositories_failed_count=(value)
    @repositories_failed_count = value.to_i
  end

  def lfs_objects_count
    @lfs_objects_count ||= lfs_objects.count
  end

  def lfs_objects_count=(value)
    @lfs_objects_count = value.to_i
  end

  def lfs_objects_synced_count
    @lfs_objects_synced_count ||= begin
      relation = Geo::FileRegistry.where(file_type: :lfs)

      if Gitlab::Geo.current_node.restricted_project_ids
        relation = relation.where(file_id: lfs_objects.pluck(:id))
      end

      relation.count
    end
  end

  def lfs_objects_synced_count=(value)
    @lfs_objects_synced_count = value.to_i
  end

  def lfs_objects_synced_in_percentage
    sync_percentage(lfs_objects_count, lfs_objects_synced_count)
  end

  def attachments_count
    @attachments_count ||= attachments.count
  end

  def attachments_count=(value)
    @attachments_count = value.to_i
  end

  def attachments_synced_count
    @attachments_synced_count ||= begin
      upload_ids = attachments.pluck(:id)
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

  def attachments
    @attachments ||= Gitlab::Geo.current_node.uploads
  end

  def lfs_objects
    @lfs_objects ||= Gitlab::Geo.current_node.lfs_objects
  end

  def project_registries
    @project_registries ||= Gitlab::Geo.current_node.project_registries
  end

  def repositories
    @repositories ||= Gitlab::Geo.current_node.projects
  end

  def latest_event
    Geo::EventLog.latest_event
  end

  def cursor_last_processed
    Geo::EventLogState.last_processed
  end
end
