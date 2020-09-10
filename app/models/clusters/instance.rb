# frozen_string_literal: true

module Clusters
  class Instance
    def clusters
      Clusters::Cluster.instance_type
    end

    def feature_available?(feature)
      ::Feature.enabled?(feature, type: :licensed, default_enabled: true)
    end

    def flipper_id
      self.class.to_s
    end
  end
end
