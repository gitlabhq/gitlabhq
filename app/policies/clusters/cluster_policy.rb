# frozen_string_literal: true

module Clusters
  class ClusterPolicy < BasePolicy
    alias_method :cluster, :subject

    delegate { cluster.group }
    delegate { cluster.project }
    delegate { cluster.instance }
  end
end
