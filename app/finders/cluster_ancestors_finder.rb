# frozen_string_literal: true

class ClusterAncestorsFinder
  include Gitlab::Utils::StrongMemoize

  def initialize(clusterable, current_user)
    @clusterable = clusterable
    @current_user = current_user
  end

  def execute
    return [] unless can_read_clusters?

    clusterable.clusters + ancestor_clusters
  end

  def has_ancestor_clusters?
    ancestor_clusters.any?
  end

  private

  attr_reader :clusterable, :current_user

  def can_read_clusters?
    Ability.allowed?(current_user, :read_cluster, clusterable)
  end

  # This unfortunately returns an Array, not a Relation!
  def ancestor_clusters
    strong_memoize(:ancestor_clusters) do
      Clusters::Cluster.ancestor_clusters_for_clusterable(clusterable)
    end
  end
end
