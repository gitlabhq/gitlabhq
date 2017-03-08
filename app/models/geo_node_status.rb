class GeoNodeStatus
  include ActiveModel::Model

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
    return 0 if repositories_count.zero?

    (repositories_synced_count.to_f / repositories_count.to_f) * 100.0
  end

  def repositories_failed_count
    @repositories_failed_count ||= Geo::ProjectRegistry.failed.count
  end

  def repositories_failed_count=(value)
    @repositories_failed_count = value.to_i
  end
end
