# frozen_string_literal: true

module API
  module Entities
    class DiscoveredClusters < Grape::Entity
      class ClusterBasic < Grape::Entity
        expose :id, documentation: { type: 'Integer', format: 'int64', example: 1 }
        expose :name, documentation: { type: 'String' }
      end

      expose :groups, documentation: { type: 'Hash' } do |object|
        object[:groups].transform_values do |clusters|
          ClusterBasic.represent(clusters)
        end
      end

      expose :projects, documentation: { type: 'Hash' } do |object|
        object[:projects].transform_values do |clusters|
          ClusterBasic.represent(clusters)
        end
      end
    end
  end
end
