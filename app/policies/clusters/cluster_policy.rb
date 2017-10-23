module Clusters
  class ClusterPolicy < BasePolicy
    alias_method :cluster, :subject

    delegate { cluster.project }

    rule { can?(:master_access) }.policy do
      enable :update_cluster
      enable :admin_cluster
    end
  end
end
