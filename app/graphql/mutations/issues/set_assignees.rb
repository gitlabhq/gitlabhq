# frozen_string_literal: true

module Mutations
  module Issues
    class SetAssignees < Base
      graphql_name 'IssueSetAssignees'

      include Assignable

      def assign!(issue, users, mode)
        permitted, forbidden = users.partition { |u| u.can?(:read_issue, issue.resource_parent) }

        super(issue, permitted, mode)

        forbidden.each do |user|
          issue.errors.add(
            :assignees,
            "Cannot assign #{user.to_reference} to #{issue.to_reference}"
          )
        end
      end

      def update_service_class
        ::Issues::UpdateService
      end
    end
  end
end
