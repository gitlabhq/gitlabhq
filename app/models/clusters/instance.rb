# frozen_string_literal: true

module Clusters
  class Instance
    def clusters
      Clusters::Cluster.instance_type
    end

    def flipper_id
      self.class.to_s
    end
  end
end
