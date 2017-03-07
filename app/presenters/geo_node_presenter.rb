class GeoNodePresenter < Gitlab::View::Presenter::Delegated
  presents :geo_node

  delegate :healthy?, :health, :repositories_count, :repositories_synced_count,
           :repositories_synced_in_percentage, :repositories_failed_count,
           to: :status

  private

  def status
    @status ||= Geo::NodeStatusService.new.call(geo_node.status_url)
  end
end
