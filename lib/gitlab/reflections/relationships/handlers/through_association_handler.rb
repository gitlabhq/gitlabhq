# frozen_string_literal: true

module Gitlab
  module Reflections
    module Relationships
      module Handlers
        # Handles has_many :through and has_one :through associations
        # Examples:
        #   has_many :users, through: :some_habtm_relation
        #   has_many :comments, through: :posts
        #   has_one :profile, through: :user
        class ThroughAssociationHandler < BaseHandler
          def relationship_attributes
            super.merge(
              foreign_key: foreign_key,
              primary_key: reflection.active_record_primary_key,
              through_table: through_table,
              through_target_key: through_target_key,
              is_through_association: true,
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

          def foreign_key
            reflection.through_reflection&.foreign_key
          end

          def through_table
            case reflection.through_reflection.macro
            when :has_and_belongs_to_many
              reflection.through_reflection.join_table
            else
              reflection.through_reflection.table_name
            end
          end

          def through_target_key
            reflection.source_reflection&.foreign_key
          end
        end
      end
    end
  end
end
