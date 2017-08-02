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

      if restricted_project_ids
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
    @attachments ||=
      if restricted_project_ids
        uploads_table   = Upload.arel_table
        group_uploads   = uploads_table[:model_type].eq('Namespace').and(uploads_table[:model_id].in(Gitlab::Geo.current_node.namespace_ids))
        project_uploads = uploads_table[:model_type].eq('Project').and(uploads_table[:model_id].in(restricted_project_ids))
        other_uploads   = uploads_table[:model_type].not_in(%w[Namespace Project])

        Upload.where(group_uploads.or(project_uploads).or(other_uploads))
      else
        Upload.all
      end
  end

  def lfs_objects
    @lfs_objects ||=
      if restricted_project_ids
        LfsObject.joins(:projects).where(projects: { id: restricted_project_ids })
      else
        LfsObject.all
      end
  end

  def project_registries
    @project_registries ||=
      if restricted_project_ids
        Geo::ProjectRegistry.where(project_id: restricted_project_ids)
      else
        Geo::ProjectRegistry.all
      end
  end

  def repositories
    @repositories ||=
      if restricted_project_ids
        Project.where(id: restricted_project_ids)
      else
        Project.all
      end
  end

  def restricted_project_ids
    return @restricted_project_ids if defined?(@restricted_project_ids)

    @restricted_project_ids = Gitlab::Geo.current_node.project_ids
  end
end
