# frozen_string_literal: true

class Admin::ClustersController < Clusters::ClustersController
  prepend_before_action :check_instance_clusters_feature_flag!

  layout 'admin'

  private

  def clusterable
    @clusterable ||= InstanceClusterablePresenter.fabricate(cluster_instance, current_user: current_user)
  end

  def cluster_instance
    @cluster_instance ||= Clusters::Instance.new
  end

  def check_instance_clusters_feature_flag!
    render_404 unless instance_clusters_enabled?
  end

  def instance_clusters_enabled?
    cluster_instance.instance_clusters_enabled?
  end
end
