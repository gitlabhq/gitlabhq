# frozen_string_literal: true

module Mutations
  module Issues
    class SetAssignees < Base
      graphql_name 'IssueSetAssignees'

      include Assignable

      def update_service_class
        ::Issues::UpdateService
      end
    end
  end
end
