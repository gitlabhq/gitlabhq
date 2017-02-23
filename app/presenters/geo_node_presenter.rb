class GeoNodePresenter < Gitlab::View::Presenter::Delegated
  presents :geo_node

  def healthy?
    health.blank?
  end

  def health
    status.health
  end

  def repositories_synced
    (status.repositories_synced.to_f / status.repositories.to_f) * 100.0
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
