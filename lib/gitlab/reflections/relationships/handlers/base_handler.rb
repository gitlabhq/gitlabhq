# frozen_string_literal: true

module Gitlab
  module Reflections
    module Relationships
      module Handlers
        class BaseHandler
          def initialize(model, association_name, reflection)
            @model = model
            @association_name = association_name
            @reflection = reflection
          end

          def build_relationships
            relationship = build_relationship(**relationship_attributes)
            relationship ? [relationship] : []
          rescue NameError
            # Skip associations where the target class doesn't exist
            # This can happen when models reference classes that have been removed
            []
          end

          attr_reader :model, :association_name, :reflection

          def relationship_attributes
            {
              parent_table: model.table_name,
              child_table: reflection.klass.table_name,
              relationship_type: relationship_type
            }
          end

          private

          def build_relationship(**attributes)
            relationship = Relationship.new(attributes.compact)
            relationship.valid? ? relationship : nil
          end

          def relationship_type
            raise NotImplementedError, "#{self.class} must implement #relationship_type"
          end
        end
      end
    end
  end
end
