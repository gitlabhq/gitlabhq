# frozen_string_literal: true

module Clusters
  class InstancePolicy < BasePolicy
    include ClusterableActions

    condition(:has_clusters, scope: :subject) { clusterable_has_clusters? }
    condition(:can_have_multiple_clusters) { multiple_clusters_available? }
    condition(:instance_clusters_enabled) { Instance.enabled? }

    rule { admin & instance_clusters_enabled }.policy do
      enable :read_cluster
      enable :add_cluster
      enable :create_cluster
      enable :update_cluster
      enable :admin_cluster
    end

    rule { ~can_have_multiple_clusters & has_clusters }.prevent :add_cluster
  end
end
