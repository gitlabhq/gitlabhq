# frozen_string_literal: true

module Mutations
  module MergeRequests
    class SetReviewers < Base
      graphql_name 'MergeRequestSetReviewers'

      authorize_granular_token permissions: :update_merge_request, boundary_argument: :project_path,
        boundary_type: :project

      def self.authorization_scopes
        super + [:ai_workflows]
      end

      argument :reviewer_usernames,
        [GraphQL::Types::String],
        required: true,
        description: 'Usernames of reviewers to assign. Replaces existing reviewers by default. ' \
          'Usernames that do not match a visible user are reported in `errors` and not assigned.'

      argument :operation_mode,
        Types::MutationOperationModeEnum,
        required: false,
        default_value: Types::MutationOperationModeEnum.default_mode,
        description: 'Operation to perform. Defaults to REPLACE.'

      def resolve(project_path:, iid:, reviewer_usernames:, operation_mode:)
        resource = authorized_find!(project_path: project_path, iid: iid)

        reviewers = UsersFinder.new(current_user, username: reviewer_usernames).execute.to_a

        # UsersFinder drops usernames it cannot resolve, and the resulting no-change
        # update is indistinguishable from a real assignment, so name them explicitly.
        unresolved = unresolved_usernames(reviewer_usernames, reviewers)

        ::MergeRequests::UpdateReviewersService.new(
          project: resource.project,
          current_user: current_user,
          params: { reviewer_ids: reviewer_ids(resource, reviewers, operation_mode) }
        ).execute(resource)

        {
          resource.class.name.underscore.to_sym => resource,
          errors: errors_on_object(resource) + unresolved_errors(unresolved)
        }
      end

      private

      def unresolved_errors(unresolved)
        return [] if unresolved.empty?

        ["Reviewers not able to be set: #{unresolved.join(', ')}"]
      end

      def unresolved_usernames(usernames, reviewers)
        # User.by_username matches case-insensitively, so compare on the same footing.
        found = reviewers.map { |user| user.username.downcase }

        usernames.uniq(&:downcase).reject { |username| found.include?(username.downcase) }
      end

      def reviewer_ids(resource, reviewers, mode)
        new_reviewer_ids = user_ids(reviewers)

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
