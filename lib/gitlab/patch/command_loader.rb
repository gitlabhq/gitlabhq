# frozen_string_literal: true

module Gitlab
  module Patch
    module CommandLoader
      extend ActiveSupport::Concern

      class_methods do
        # Shuffle the node list to spread out initial connection creation amongst all nodes
        #
        # The input is a Redis::Cluster::Node instance which is an Enumerable.
        #  `super` receives an Array of Redis::Client instead of a Redis::Cluster::Node
        def load(nodes)
          super(nodes.to_a.shuffle)
        end
      end
    end
  end
end
