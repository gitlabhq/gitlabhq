# frozen_string_literal: true

module Mutations
  module MergeRequests
    class Update < Base
      graphql_name 'MergeRequestUpdate'

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
               description: 'Estimated time to complete the merge request, or `0` to remove the current estimate.'

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
        if !time_estimate.nil? && Gitlab::TimeTrackingFormatter.parse(time_estimate, keep_zero: true).nil?
          raise Gitlab::Graphql::Errors::ArgumentError,
                'timeEstimate must be formatted correctly, for example `1h 30m`'
        end

        super
      end

      private

      def parse_arguments(args)
        unless args[:time_estimate].nil?
          args[:time_estimate] = Gitlab::TimeTrackingFormatter.parse(args[:time_estimate], keep_zero: true)
        end

        args.compact
      end
    end
  end
end
