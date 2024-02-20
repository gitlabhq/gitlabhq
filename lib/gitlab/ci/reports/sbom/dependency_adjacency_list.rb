# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class DependencyAdjacencyList
          def initialize
            @adjacency_list = Hash.new { |hash, key| hash[key] = [] }
            @component_info = {}
          end

          def add_edge(parent, child)
            adjacency_list[child] << parent
          end

          def add_component_info(ref, name, version)
            component_info[ref] = { name: name, version: version }
          end

          def ancestors_for(child)
            ancestors_ref_for(child).filter_map do |ancestor_ref|
              component_info[ancestor_ref]
            end
          end

          private

          def ancestors_ref_for(child)
            adjacency_list[child]
          end

          attr_reader :adjacency_list, :component_info
        end
      end
    end
  end
end
