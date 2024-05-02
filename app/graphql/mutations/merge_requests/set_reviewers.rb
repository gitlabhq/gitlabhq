# frozen_string_literal: true

module Mutations
  module MergeRequests
    class SetReviewers < Base
      graphql_name 'MergeRequestSetReviewers'

      argument :reviewer_usernames,
        [GraphQL::Types::String],
        required: true,
        description: 'Usernames of reviewers to assign. Replaces existing reviewers by default.'

      argument :operation_mode,
        Types::MutationOperationModeEnum,
        required: false,
        default_value: Types::MutationOperationModeEnum.default_mode,
        description: 'Operation to perform. Defaults to REPLACE.'

      def resolve(project_path:, iid:, reviewer_usernames:, operation_mode:)
        resource = authorized_find!(project_path: project_path, iid: iid)

        ::MergeRequests::UpdateReviewersService.new(
          project: resource.project,
          current_user: current_user,
          params: { reviewer_ids: reviewer_ids(resource, reviewer_usernames, operation_mode) }
        ).execute(resource)

        {
          resource.class.name.underscore.to_sym => resource,
          errors: errors_on_object(resource)
        }
      end

      private

      def reviewer_ids(resource, usernames, mode)
        new_reviewers = UsersFinder.new(current_user, username: usernames).execute.to_a
        new_reviewer_ids = user_ids(new_reviewers)

        case mode
        when 'REPLACE' then new_reviewer_ids
        when 'APPEND' then user_ids(resource.reviewers) | new_reviewer_ids
        when 'REMOVE' then user_ids(resource.reviewers) - new_reviewer_ids
        end
      end

      def user_ids(users)
        users.map(&:id)
      end
    end
  end
end
