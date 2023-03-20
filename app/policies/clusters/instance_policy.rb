# frozen_string_literal: true

module Clusters
  class InstancePolicy < BasePolicy
    rule { admin }.policy do
      enable :read_cluster
      enable :add_cluster
      enable :create_cluster
      enable :update_cluster
      enable :admin_cluster
      enable :read_prometheus
      enable :use_k8s_proxies
    end
  end
end

Clusters::InstancePolicy.prepend_mod_with('Clusters::InstancePolicy')
