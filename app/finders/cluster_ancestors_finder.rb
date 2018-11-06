# frozen_string_literal: true

class ClusterAncestorsFinder
  def initialize(clusterable, user)
    @clusterable = clusterable
    @user = user
  end

  def execute
    clusterable.clusters + ancestor_clusters
  end

  private

  attr_reader :clusterable, :user

  def ancestor_clusters
    Clusters::Cluster.ancestor_clusters_for_clusterable(clusterable)
  end
end
