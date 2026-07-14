# frozen_string_literal: true

module Mutations
  module MergeRequests
    class SetAssignees < Base
      graphql_name 'MergeRequestSetAssignees'

      authorize_granular_token permissions: :update_merge_request, boundary_argument: :project_path,
        boundary_type: :project

      include Assignable

      def update_service_class
        ::MergeRequests::UpdateAssigneesService
      end
    end
  end
end
