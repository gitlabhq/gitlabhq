module Clusters
  class UpdateService < BaseService
    def execute(cluster)
      cluster.update(params)
    end
  end
end
