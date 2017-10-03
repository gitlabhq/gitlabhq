module Gcp
  class ClusterPolicy < BasePolicy
    alias_method :cluster, :subject

    delegate { @subject.project }

    condition(:safe_to_change) do
      can?(:master_access) && !cluster.on_creation?
    end

    rule { safe_to_change }.policy do
      enable :update_cluster
      enable :admin_cluster
    end
  end
end
