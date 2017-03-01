class GeoNodePresenter < Gitlab::View::Presenter::Delegated
  presents :geo_node

  def healthy?
    health.blank?
  end

  def health
    status.health
  end

  def repositories
    status.repositories.to_i
  end

  def repositories_synced
    status.repositories_synced.to_i
  end

  def repositories_synced_in_percentage
    return 0 if repositories.zero?

    (repositories_synced.to_f / repositories.to_f) * 100.0
  end

  def repositories_failed
    status.repositories_failed.to_i
  end

  private

  def status
    @status ||= Geo::NodeStatusService.new.call(status_url)
  end
end
