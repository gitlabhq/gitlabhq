# frozen_string_literal: true

class ClusterAncestorsFinder
  def initialize(clusterable, current_user)
    @clusterable = clusterable
    @current_user = current_user
  end

  def execute
    return [] unless can_read_clusters?

    clusterable.clusters + ancestor_clusters
  end

  private

  attr_reader :clusterable, :current_user

  def can_read_clusters?
    Ability.allowed?(current_user, :read_cluster, clusterable)
  end

  def ancestor_clusters
    Clusters::Cluster.ancestor_clusters_for_clusterable(clusterable)
  end
end
