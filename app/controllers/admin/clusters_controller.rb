# frozen_string_literal: true

class Admin::ClustersController < Clusters::ClustersController
  prepend_before_action :check_instance_clusters_feature_flag!

  layout 'admin'

  private

  def clusterable
    @clusterable ||= InstanceClusterablePresenter.fabricate(Clusters::Instance.new, current_user: current_user)
  end

  def check_instance_clusters_feature_flag!
    render_404 unless Feature.enabled?(:instance_clusters, default_enabled: true)
  end
end
