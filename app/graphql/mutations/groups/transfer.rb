# frozen_string_literal: true

module Mutations
  # rubocop: disable Gitlab/BoundedContexts -- generic mutation for group transfer
  module Groups
    class Transfer < BaseMutation
      graphql_name 'GroupTransfer'

      authorize :change_group

      authorize_granular_token permissions: :transfer_group,
        boundary_argument: :id,
        boundary_type: :group

      argument :id,
        ::Types::GlobalIDType[::Group],
        required: true,
        description: 'Global ID of the group to transfer.'

      argument :target_id,
        ::Types::GlobalIDType[::Group],
        required: false,
        description: 'Global ID of the target parent group. Omit to make group top-level.'

      field :group,
        Types::GroupType,
        null: true,
        description: 'Group after mutation.'

      def resolve(id:, target_id: nil)
        # Authorization and lookups for group transfers issue more queries than the
        # default threshold allows. Mirrors the existing exemption for the group
        # update/transfer REST endpoint. See lib/api/groups.rb#check_query_limit.
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/586401', new_threshold: 110)

        group = authorized_find!(id)
        target_group = find_object(target_id)&.sync if target_id
        raise_resource_not_available_error!('Target group not found.') if target_id && target_group.nil?

        service = ::Groups::TransferService.new(group, current_user)
        result = service.schedule_async_transfer(target_group)

        if result.success?
          { group: group, errors: [] }
        else
          { group: group, errors: [result.message] }
        end
      end

      private

      def find_object(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
  # rubocop: enable Gitlab/BoundedContexts
end

Mutations::Groups::Transfer.prepend_mod_with('Mutations::Groups::Transfer')
