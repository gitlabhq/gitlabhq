# frozen_string_literal: true

class ClustersFinder < UnionFinder
  def initialize(project, user, scope)
    @project = project
    @user = user
    @scope = scope || :active
  end

  def execute
    clusters = project.clusters
    clusters = filter_by_scope(clusters)

    Clusters::Cluster.from_union([clusters, project.group_clusters])
  end

  private

  attr_reader :project, :user, :scope

  def filter_by_scope(clusters)
    case scope.to_sym
    when :all
      clusters
    when :inactive
      clusters.disabled
    when :active
      clusters.enabled
    else
      raise "Invalid scope #{scope}"
    end
  end
end
