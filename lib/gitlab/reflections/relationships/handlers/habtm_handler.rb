# frozen_string_literal: true

module Gitlab
  module Reflections
    module Relationships
      module Handlers
        # Handles has_and_belongs_to_many associations
        # Examples:
        #   has_and_belongs_to_many :tags
        #   has_and_belongs_to_many :users, join_table: 'project_users'
        class HabtmHandler < BaseHandler
          def relationship_attributes
            super.merge(
              through_table: reflection.join_table,
              foreign_key: reflection.foreign_key,
              primary_key: reflection.active_record_primary_key,
              parent_association: {
                name: association_name.to_s,
                type: reflection.macro.to_s,
                model: model.name
              }
            )
          end

          private

          def relationship_type
            'many_to_many'
          end
        end
      end
    end
  end
end
