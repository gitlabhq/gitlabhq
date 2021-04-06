# frozen_string_literal: true

module Mutations
  module MergeRequests
    class SetAssignees < Base
      graphql_name 'MergeRequestSetAssignees'

      include Assignable

      def update_service_class
        ::MergeRequests::UpdateAssigneesService
      end
    end
  end
end
