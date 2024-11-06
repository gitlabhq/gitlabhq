# frozen_string_literal: true

module Mutations
  module Issues
    class Update < Base
      graphql_name 'UpdateIssue'

      include CommonMutationArguments
      include ValidateTimeEstimate

      argument :title, GraphQL::Types::String,
        required: false,
        description: copy_field_description(Types::IssueType, :title)

      argument :milestone_id, GraphQL::Types::ID, # rubocop: disable Graphql/IDType
        required: false,
        description: 'ID of the milestone to assign to the issue. On update milestone will be removed if set to null.'

      argument :add_label_ids, [GraphQL::Types::ID],
        required: false,
        description: 'IDs of labels to be added to the issue.'

      argument :remove_label_ids, [GraphQL::Types::ID],
        required: false,
        description: 'IDs of labels to be removed from the issue.'

      argument :label_ids, [GraphQL::Types::ID],
        required: false,
        description: 'IDs of labels to be set. Replaces existing issue labels.'

      argument :state_event, Types::IssueStateEventEnum,
        description: 'Close or reopen an issue.',
        required: false

      argument :time_estimate, GraphQL::Types::String,
        required: false,
        description: 'Estimated time to complete the issue. ' \
          'Use `null` or `0` to remove the current estimate.'

      def resolve(project_path:, iid:, **args)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project

        args = parse_arguments(args)

        ::Issues::UpdateService.new(
          container: project,
          current_user: current_user,
          params: args,
          perform_spam_check: true
        ).execute(issue)

        {
          issue: issue,
          errors: errors_on_object(issue)
        }
      end

      def ready?(label_ids: [], add_label_ids: [], remove_label_ids: [], time_estimate: nil, **args)
        if label_ids.any? && (add_label_ids.any? || remove_label_ids.any?)
          raise Gitlab::Graphql::Errors::ArgumentError,
            'labelIds is mutually exclusive with any of addLabelIds or removeLabelIds'
        end

        validate_time_estimate(time_estimate)

        super
      end

      private

      def parse_arguments(args)
        args[:add_label_ids] = parse_label_ids(args[:add_label_ids])
        args[:remove_label_ids] = parse_label_ids(args[:remove_label_ids])
        args[:label_ids] = parse_label_ids(args[:label_ids])

        if args.key?(:time_estimate)
          args[:time_estimate] =
            args[:time_estimate].nil? ? 0 : Gitlab::TimeTrackingFormatter.parse(args[:time_estimate], keep_zero: true)
        end

        args
      end

      def parse_label_ids(ids)
        ids&.map do |gid|
          GitlabSchema.parse_gid(gid, expected_type: ::Label).model_id
        rescue Gitlab::Graphql::Errors::ArgumentError
          gid
        end
      end
    end
  end
end

Mutations::Issues::Update.prepend_mod_with('Mutations::Issues::Update')
