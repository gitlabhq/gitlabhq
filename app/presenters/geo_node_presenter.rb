class GeoNodePresenter < Gitlab::View::Presenter::Delegated
  presents :geo_node

  delegate :healthy?, :health, :repositories, :repositories_synced,
           :repositories_synced_in_percentage, :repositories_failed,
           to: :status

  private

  def status
    @status ||= Geo::NodeStatusService.new.call(status_url)
  end
end
