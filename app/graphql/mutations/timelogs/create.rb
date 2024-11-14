# frozen_string_literal: true

module Mutations
  module Timelogs
    class Create < Base
      graphql_name 'TimelogCreate'

      argument :time_spent,
        GraphQL::Types::String,
        required: true,
        description: 'Amount of time spent.'

      argument :spent_at,
        Types::TimeType,
        required: false,
        description: 'Timestamp of when the time was spent. If empty, defaults to current time.'

      argument :summary,
        GraphQL::Types::String,
        required: true,
        description: 'Summary of time spent.'

      argument :issuable_id,
        ::Types::GlobalIDType[::Issuable],
        required: true,
        description: 'Global ID of the issuable (Issue, WorkItem or MergeRequest).'

      authorize :create_timelog

      def resolve(issuable_id:, time_spent:, summary:, **args)
        parsed_time_spent = Gitlab::TimeTrackingFormatter.parse(time_spent)
        if parsed_time_spent.nil?
          return { timelog: nil, errors: [_('Time spent must be formatted correctly. For example: 1h 30m.')] }
        end

        issuable = authorized_find!(id: issuable_id)

        spent_at = args[:spent_at].nil? ? DateTime.current : args[:spent_at]

        result = ::Timelogs::CreateService.new(
          issuable, parsed_time_spent, spent_at, summary, current_user
        ).execute

        response(result)
      end

      private

      def find_object(id:)
        GitlabSchema.object_from_id(id, expected_type: [::Issue, ::WorkItem, ::MergeRequest]).sync
      end
    end
  end
end
