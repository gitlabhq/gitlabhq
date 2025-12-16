# frozen_string_literal: true

module Gitlab
  module Reflections
    module Relationships
      module Handlers
        # Handles polymorphic has_many and has_one associations with :as option
        # Examples:
        #   has_many :comments, as: :commentable
        #   has_one :image, as: :imageable
        class PolymorphicHasAssociationHandler < BaseHandler
          def relationship_attributes
            polymorphic_name = reflection.options[:as].to_s

            {
              parent_table: model.table_name,
              child_table: nil, # Will be filled in for specific targets
              primary_key: reflection.active_record_primary_key,
              foreign_key: "#{polymorphic_name}_id",
              relationship_type: relationship_type,
              polymorphic: true,
              polymorphic_type_column: "#{polymorphic_name}_type",
              polymorphic_name: polymorphic_name,
              parent_association: {
                name: association_name.to_s,
                type: reflection.macro.to_s,
                model: model.name
              }
            }
          end

          private

          def relationship_type
            case reflection.macro
            when :has_many
              'one_to_many'
            when :has_one
              'one_to_one'
            end
          end
        end
      end
    end
  end
end
