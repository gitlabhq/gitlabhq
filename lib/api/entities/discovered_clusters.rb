# frozen_string_literal: true

module API
  module Entities
    class DiscoveredClusters < Grape::Entity
      class ClusterBasic < Grape::Entity
        expose :id
        expose :name
      end

      expose :groups do |object|
        object[:groups].transform_values do |clusters|
          ClusterBasic.represent(clusters)
        end
      end

      expose :projects do |object|
        object[:projects].transform_values do |clusters|
          ClusterBasic.represent(clusters)
        end
      end
    end
  end
end
