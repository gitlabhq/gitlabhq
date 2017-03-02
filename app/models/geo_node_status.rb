class GeoNodeStatus
  include ActiveModel::Model

  attr_writer :health

  def health
    @health ||= HealthCheck::Utils.process_checks(['geo'])
  end

  def healthy?
    health.blank?
  end

  def repositories
    @repositories ||= Project.count
  end

  def repositories=(value)
    @repositories = value.to_i
  end

  def repositories_synced
    @repositories_synced ||= Geo::ProjectRegistry.synced.count
  end

  def repositories_synced=(value)
    @repositories_synced = value.to_i
  end

  def repositories_synced_in_percentage
    return 0 if repositories.zero?

    (repositories_synced.to_f / repositories.to_f) * 100.0
  end

  def repositories_failed
    @repositories_failed ||= Geo::ProjectRegistry.failed.count
  end

  def repositories_failed=(value)
    @repositories_failed = value.to_i
  end
end
