# frozen_string_literal: true

module Mutations
  module Members
    module Groups
      class BulkUpdate < ::Mutations::BaseMutation
        graphql_name 'GroupMemberBulkUpdate'

        include Gitlab::Utils::StrongMemoize

        authorize :admin_group_member

        field :group_members,
              [Types::GroupMemberType],
              null: true,
              description: 'Group members after mutation.'

        argument :group_id,
                 ::Types::GlobalIDType[::Group],
                 required: true,
                 description: 'Global ID of the group.'

        argument :user_ids,
                 [::Types::GlobalIDType[::User]],
                 required: true,
                 description: 'Global IDs of the group members.'

        argument :access_level,
                 ::Types::MemberAccessLevelEnum,
                 required: true,
                 description: 'Access level to update the members to.'

        argument :expires_at,
                 Types::TimeType,
                 required: false,
                 description: 'Date and time the membership expires.'

        MAX_MEMBERS_UPDATE_LIMIT = 50
        MAX_MEMBERS_UPDATE_ERROR = "Count of members to be updated should be less than #{MAX_MEMBERS_UPDATE_LIMIT}."
        INVALID_MEMBERS_ERROR = 'Only access level of direct members can be updated.'

        def resolve(group_id:, **args)
          result = ::Members::UpdateService.new(current_user, args.except(:user_ids)).execute(@updatable_group_members)

          {
            group_members: result[:members],
            errors: Array.wrap(result[:message])
          }
        rescue Gitlab::Access::AccessDeniedError
          {
            errors: ["Unable to update members, please check user permissions."]
          }
        end

        private

        def ready?(**args)
          group = authorized_find!(group_id: args[:group_id])
          user_ids = args.fetch(:user_ids, {}).map(&:model_id)
          @updatable_group_members = only_direct_group_members(group, user_ids)

          if @updatable_group_members.size > MAX_MEMBERS_UPDATE_LIMIT
            raise Gitlab::Graphql::Errors::InvalidMemberCountError, MAX_MEMBERS_UPDATE_ERROR
          end

          if @updatable_group_members.size != user_ids.size
            raise Gitlab::Graphql::Errors::InvalidMembersError, INVALID_MEMBERS_ERROR
          end

          super
        end

        def find_object(group_id:)
          GitlabSchema.object_from_id(group_id, expected_type: ::Group)
        end

        def only_direct_group_members(group, user_ids)
          group
            .members
            .with_user(user_ids).to_a
        end
      end
    end
  end
end
