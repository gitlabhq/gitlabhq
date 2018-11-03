# frozen_string_literal: true

class ClustersFinder
  def initialize(clusterable, user, scope)
    @clusterable = clusterable
    @user = user
    @scope = scope || :active
  end

  def execute
    clusters = clusterable.clusters
    filter_by_scope(clusters)
  end

  private

  attr_reader :clusterable, :user, :scope

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
