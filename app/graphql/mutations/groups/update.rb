# frozen_string_literal: true

module Mutations
  module Groups
    class Update < Mutations::BaseMutation
      graphql_name 'GroupUpdate'

      include ::Gitlab::Allowable
      include Mutations::ResolvesGroup

      authorize :admin_group_or_admin_runner

      field :group, Types::GroupType,
        null: true,
        description: 'Group after update.'

      argument :full_path, GraphQL::Types::ID,
        required: true,
        description: 'Full path of the group that will be updated.'
      argument :lock_math_rendering_limits_enabled, GraphQL::Types::Boolean,
        required: false,
        description: copy_field_description(Types::GroupType, :lock_math_rendering_limits_enabled)
      argument :math_rendering_limits_enabled, GraphQL::Types::Boolean,
        required: false,
        description: copy_field_description(Types::GroupType, :math_rendering_limits_enabled)
      argument :name, GraphQL::Types::String,
        required: false,
        description: copy_field_description(Types::GroupType, :name)
      argument :path, GraphQL::Types::String,
        required: false,
        description: copy_field_description(Types::GroupType, :path)
      argument :shared_runners_setting, Types::Namespace::SharedRunnersSettingEnum,
        required: false,
        description: copy_field_description(Types::GroupType, :shared_runners_setting)
      argument :visibility, Types::VisibilityLevelsEnum,
        required: false,
        description: copy_field_description(Types::GroupType, :visibility)

      def resolve(full_path:, **args)
        group = authorized_find!(full_path: full_path)

        unless ::Groups::UpdateService.new(group, current_user, authorized_args(group, args)).execute
          return { group: nil, errors: group.errors.full_messages }
        end

        { group: group, errors: [] }
      end

      private

      def find_object(full_path:)
        resolve_group(full_path: full_path)
      end

      def authorized_args(group, args)
        return args if can?(current_user, :admin_group, group)

        if can?(current_user, :admin_runner, group) && args.keys == [:shared_runners_setting]
          return { shared_runners_setting: args[:shared_runners_setting] }
        end

        raise_resource_not_available_error!
      end
    end
  end
end

Mutations::Groups::Update.prepend_mod_with('Mutations::Groups::Update')
