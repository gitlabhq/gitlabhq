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
               Types::DateType,
               required: true,
               description: 'When the time was spent.'

      argument :summary,
               GraphQL::Types::String,
               required: true,
               description: 'Summary of time spent.'

      argument :issuable_id,
               ::Types::GlobalIDType[::Issuable],
               required: true,
               description: 'Global ID of the issuable (Issue, WorkItem or MergeRequest).'

      authorize :create_timelog

      def resolve(issuable_id:, time_spent:, spent_at:, summary:, **args)
        issuable = authorized_find!(id: issuable_id)
        parsed_time_spent = Gitlab::TimeTrackingFormatter.parse(time_spent)

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
