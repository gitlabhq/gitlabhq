# frozen_string_literal: true

module BulkImports
  module Groups
    module Loaders
      class GroupLoader
        def load(context, data)
          return unless user_can_create_group?(context.current_user, data)

          group = ::Groups::CreateService.new(context.current_user, data).execute

          context.entity.update!(group: group)

          group
        end

        private

        def user_can_create_group?(current_user, data)
          if data['parent_id']
            parent = Namespace.find_by_id(data['parent_id'])

            Ability.allowed?(current_user, :create_subgroup, parent)
          else
            Ability.allowed?(current_user, :create_group)
          end
        end
      end
    end
  end
end
