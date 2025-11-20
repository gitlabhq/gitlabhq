# frozen_string_literal: true

module Gitlab
  module Reflections
    module Relationships
      module Transformers
        # Filters out invalid relationships from the collection
        class Validate
          def self.call(relationships)
            new(relationships).transform
          end

          def initialize(relationships)
            @relationships = relationships
          end

          def transform
            @relationships.filter_map do |rel|
              rel.valid? ? rel : nil
            end
          end
        end
      end
    end
  end
end
