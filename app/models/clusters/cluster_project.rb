module Clusters
  class ClusterProject < ActiveRecord::Base
    belongs_to :cluster
    belongs_to :project
  end
end
