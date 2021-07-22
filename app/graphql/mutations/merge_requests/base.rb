# frozen_string_literal: true

module Mutations
  module MergeRequests
    class Base < BaseMutation
      include Mutations::ResolvesIssuable

      argument :project_path, GraphQL::Types::ID,
               required: true,
               description: "The project the merge request to mutate is in."

      argument :iid, GraphQL::Types::String,
               required: true,
               description: "The IID of the merge request to mutate."

      field :merge_request,
            Types::MergeRequestType,
            null: true,
            description: "The merge request after mutation."

      authorize :update_merge_request

      private

      def find_object(project_path:, iid:)
        resolve_issuable(type: :merge_request, parent_path: project_path, iid: iid)
      end
    end
  end
end
