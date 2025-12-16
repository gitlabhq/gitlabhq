# frozen_string_literal: true

module Gitlab
  module Reflections
    module Relationships
      module Handlers
        # Handles Active Storage file attachment associations
        # Examples:
        #   has_many_attached :images
        #   has_one_attached :avatar
        class ActiveStorageHandler < BaseHandler
          def relationship_attributes
            super.merge(
              child_table: 'active_storage_attachments',
              foreign_key: 'record_id',
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
            when :has_many_attached
              'one_to_many'
            when :has_one_attached
              'one_to_one'
            end
          end
        end
      end
    end
  end
end
