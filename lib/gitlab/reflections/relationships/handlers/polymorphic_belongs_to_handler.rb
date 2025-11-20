# frozen_string_literal: true

module Gitlab
  module Reflections
    module Relationships
      module Handlers
        # Handles polymorphic belongs_to associations
        # Examples:
        #   belongs_to :commentable, polymorphic: true
        #   belongs_to :imageable, polymorphic: true
        class PolymorphicBelongsToHandler < BaseHandler
          def relationship_attributes
            {
              parent_table: nil, # Will be filled in for specific targets
              child_table: model.table_name,
              primary_key: model.primary_key,
              foreign_key: reflection.foreign_key,
              relationship_type: relationship_type,
              polymorphic: true,
              polymorphic_type_column: reflection.foreign_type,
              polymorphic_name: reflection.name.to_s,
              child_association: {
                name: association_name.to_s,
                type: reflection.macro.to_s,
                model: model.name
              }
            }
          end

          private

          def relationship_type
            'many_to_one'
          end
        end
      end
    end
  end
end
