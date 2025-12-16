# frozen_string_literal: true

module Gitlab
  module Reflections
    module Relationships
      module Handlers
        # Handles direct has_many and has_one associations (non-through)
        # Examples:
        #   has_many :posts
        #   has_one :profile
        #   has_many :comments, foreign_key: 'author_id'
        class HasAssociationHandler < BaseHandler
          def relationship_attributes
            super.merge(
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
