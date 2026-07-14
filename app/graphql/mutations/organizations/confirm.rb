# frozen_string_literal: true

module Mutations
  module Organizations
    class Confirm < BaseMutation
      graphql_name 'OrganizationConfirm'

      authorize :update_organization
      authorize_granular_token permissions: :update_organization, boundary: :instance, boundary_type: :instance

      field :organization,
        ::Types::Organizations::OrganizationType,
        null: true,
        description: 'Organization after mutation.'

      argument :id,
        Types::GlobalIDType[::Organizations::Organization],
        required: true,
        description: 'Global ID of the organization to confirm.'

      argument :groups,
        [Types::GlobalIDType[::Group]],
        required: false,
        description: 'Global IDs of top-level groups to transfer to the organization.'

      def resolve(id:, groups: [])
        organization = authorized_find!(id: id)
        group_ids = groups.map(&:model_id)

        result = ::Organizations::ConfirmService.new(
          current_user,
          { organization_id: organization.id, group_ids: group_ids }
        ).execute

        { organization: result.payload[:organization], errors: result.errors }
      end
    end
  end
end
