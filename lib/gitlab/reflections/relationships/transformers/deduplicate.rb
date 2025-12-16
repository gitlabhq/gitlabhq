# frozen_string_literal: true

module Gitlab
  module Reflections
    module Relationships
      module Transformers
        # Removes duplicate relationships based on their signature
        class Deduplicate
          def self.call(relationships)
            new(relationships).transform
          end

          def initialize(relationships)
            @relationships = relationships
          end

          def transform
            signatures = Set.new
            @relationships.filter_map do |rel|
              rel if signatures.add?(relationship_signature(rel))
            end
          end

          private

          # Create a signature that uniquely identifies a relationship
          def relationship_signature(rel)
            [
              rel.parent_table,
              rel.child_table,
              rel.primary_key,
              rel.foreign_key,
              rel.relationship_type,
              rel.polymorphic_type_value
            ].compact.join('|')
          end
        end
      end
    end
  end
end
