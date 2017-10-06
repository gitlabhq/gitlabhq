module Gcp
  class ClusterPolicy < BasePolicy
    alias_method :cluster, :subject

    delegate { @subject.project }

    rule { can?(:master_access) }.policy do
      enable :update_cluster
      enable :admin_cluster
    end
  end
end
