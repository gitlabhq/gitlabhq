# frozen_string_literal: true

module Mutations
  module Members
    module Groups
      class BulkUpdate < BulkUpdateBase
        graphql_name 'GroupMemberBulkUpdate'
        authorize :admin_group_member

        field :group_members,
          [Types::GroupMemberType],
          null: true,
          description: 'Group members after mutation.'

        argument :group_id,
          ::Types::GlobalIDType[::Group],
          required: true,
          description: 'Global ID of the group.'

        def source_type
          ::Group
        end
      end
    end
  end
end
