# frozen_string_literal: true

module Gitlab
  module Reflections
    module Relationships
      module Handlers
        # Handles belongs_to associations (non-polymorphic)
        # Examples:
        #   belongs_to :user
        #   belongs_to :author, class_name: 'User'
        #   belongs_to :project, foreign_key: 'project_id'
        class BelongsToHandler < BaseHandler
          def relationship_attributes
            {
              parent_table: reflection.klass.table_name,
              child_table: model.table_name,
              primary_key: reflection.association_primary_key,
              foreign_key: reflection.foreign_key,
              relationship_type: relationship_type,
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
