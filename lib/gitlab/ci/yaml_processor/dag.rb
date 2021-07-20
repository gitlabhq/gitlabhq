# frozen_string_literal: true

# Represents Dag pipeline
module Gitlab
  module Ci
    class YamlProcessor
      class Dag
        include TSort

        MissingNodeError = Class.new(StandardError)

        def initialize(nodes)
          @nodes = nodes
        end

        def self.check_circular_dependencies!(jobs)
          nodes = jobs.values.to_h do |job|
            name = job[:name].to_s
            needs = job.dig(:needs, :job).to_a

            [name, needs.map { |need| need[:name].to_s }]
          end

          new(nodes).tsort
        rescue TSort::Cyclic
          raise ValidationError, 'The pipeline has circular dependencies.'
        rescue MissingNodeError
        end

        def tsort_each_child(node, &block)
          raise MissingNodeError, "node #{node} is missing" unless @nodes[node]

          @nodes[node].each(&block)
        end

        def tsort_each_node(&block)
          @nodes.each_key(&block)
        end
      end
    end
  end
end
