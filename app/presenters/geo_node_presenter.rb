class GeoNodePresenter < Gitlab::View::Presenter::Delegated
  presents :geo_node

  def healthy?
    health.blank?
  end

  def health
    status.health
  end

  def repositories
    status.repositories
  end

  def repositories_synced
    status.repositories_synced
  end

  def repositories_synced_in_percentage
    (repositories_synced.to_f / repositories.to_f) * 100.0
  end

  def repositories_failed
    status.repositories_failed
  end

  private

  def status
    @status ||= begin
      _, status = Geo::NodeStatusService.new.call(status_url)
      status
    end
  end
end
