# frozen_string_literal: true

module Mutations
  module Members
    class BulkUpdateBase < BaseMutation
      include ::API::Helpers::MembersHelpers

      argument :user_ids,
        [::Types::GlobalIDType[::User]],
        required: true,
        description: 'Global IDs of the members.'

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
                                   .freeze
      INVALID_MEMBERS_ERROR = 'Only access level of direct members can be updated.'

      def resolve(**args)
        source = authorized_find!(source_id: args[source_id_param_name])

        result = ::Members::UpdateService
                   .new(current_user, args.except(:user_ids, source_id_param_name).merge({ source: source }))
                   .execute(@updatable_members)

        present_result(result)
      rescue Gitlab::Access::AccessDeniedError
        {
          errors: ["Unable to update members, please check user permissions."]
        }
      end

      private

      def ready?(**args)
        source = authorized_find!(source_id: args[source_id_param_name])
        user_ids = args.fetch(:user_ids, {}).map(&:model_id)
        @updatable_members = only_direct_members(source, user_ids)

        if @updatable_members.size > MAX_MEMBERS_UPDATE_LIMIT
          raise Gitlab::Graphql::Errors::InvalidMemberCountError, MAX_MEMBERS_UPDATE_ERROR
        end

        if @updatable_members.size != user_ids.size
          raise Gitlab::Graphql::Errors::InvalidMembersError, INVALID_MEMBERS_ERROR
        end

        super
      end

      def find_object(source_id:)
        GitlabSchema.object_from_id(source_id, expected_type: source_type)
      end

      def only_direct_members(source, user_ids)
        source_members(source)
          .with_user(user_ids)
          .to_a
      end

      def source_id_param_name
        "#{source_name}_id".to_sym
      end

      def source_members_key
        "#{source_name}_members".to_sym
      end

      def source_name
        source_type.name.downcase
      end

      def present_result(result)
        {
          source_members_key => result[:members],
          errors: Array.wrap(result[:message])
        }
      end

      def source_type
        raise NotImplementedError
      end
    end
  end
end

Mutations::Members::BulkUpdateBase.prepend_mod
