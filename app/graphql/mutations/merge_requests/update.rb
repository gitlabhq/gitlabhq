# frozen_string_literal: true

module Mutations
  module MergeRequests
    class Update < Base
      graphql_name 'MergeRequestUpdate'

      include ValidateTimeEstimate

      description 'Update attributes of a merge request'

      argument :title, GraphQL::Types::String,
        required: false,
        description: copy_field_description(Types::MergeRequestType, :title)

      argument :target_branch, GraphQL::Types::String,
        required: false,
        description: copy_field_description(Types::MergeRequestType, :target_branch)

      argument :description, GraphQL::Types::String,
        required: false,
        description: copy_field_description(Types::MergeRequestType, :description)

      argument :state, ::Types::MergeRequestStateEventEnum,
        required: false,
        as: :state_event,
        description: 'Action to perform to change the state.'

      argument :time_estimate, GraphQL::Types::String,
        required: false,
        description: 'Estimated time to complete the merge request. ' \
          'Use `null` or `0` to remove the current estimate.'

      argument :merge_after, ::Types::TimeType,
        required: false,
        description: copy_field_description(Types::MergeRequestType, :merge_after)

      def resolve(project_path:, iid:, **args)
        merge_request = authorized_find!(project_path: project_path, iid: iid)
        args = parse_arguments(args)

        ::MergeRequests::UpdateService
          .new(project: merge_request.project, current_user: current_user, params: args)
          .execute(merge_request)

        errors = errors_on_object(merge_request)

        {
          merge_request: merge_request.reset,
          errors: errors
        }
      end

      def ready?(time_estimate: nil, **args)
        validate_time_estimate(time_estimate)

        super
      end

      private

      def parse_arguments(args)
        if args.key?(:time_estimate)
          args[:time_estimate] =
            args[:time_estimate].nil? ? 0 : Gitlab::TimeTrackingFormatter.parse(args[:time_estimate], keep_zero: true)
        end

        args.compact
      end
    end
  end
end

Mutations::MergeRequests::Update.prepend_mod_with('Mutations::MergeRequests::Update')
