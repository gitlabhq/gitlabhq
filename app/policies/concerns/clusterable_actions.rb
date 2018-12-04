# frozen_string_literal: true

module ClusterableActions
  private

  # Overridden on EE module
  def multiple_clusters_available?
    false
  end

  def clusterable_has_clusters?
    !subject.clusters.empty?
  end
end
