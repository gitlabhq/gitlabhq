# frozen_string_literal: true

module Mutations
  module Groups
    class Update < Mutations::BaseMutation
      graphql_name 'GroupUpdate'

      include Mutations::ResolvesGroup

      authorize :admin_group

      field :group, Types::GroupType,
            null: true,
            description: 'Group after update.'

      argument :full_path, GraphQL::Types::ID,
               required: true,
               description: 'Full path of the group that will be updated.'
      argument :shared_runners_setting, Types::Namespace::SharedRunnersSettingEnum,
               required: true,
               description: copy_field_description(Types::GroupType, :shared_runners_setting)

      def resolve(full_path:, **args)
        group = authorized_find!(full_path: full_path)

        unless ::Groups::UpdateService.new(group, current_user, args).execute
          return { group: nil, errors: group.errors.full_messages }
        end

        { group: group, errors: [] }
      end

      private

      def find_object(full_path:)
        resolve_group(full_path: full_path)
      end
    end
  end
end
