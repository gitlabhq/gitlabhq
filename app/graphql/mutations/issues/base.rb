# frozen_string_literal: true

module Mutations
  module Issues
    class Base < BaseMutation
      include Mutations::ResolvesProject

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: "The project the issue to mutate is in"

      argument :iid, GraphQL::STRING_TYPE,
               required: true,
               description: "The iid of the issue to mutate"

      field :issue,
            Types::IssueType,
            null: true,
            description: "The issue after mutation"

      authorize :update_issue

      private

      def find_object(project_path:, iid:)
        project = resolve_project(full_path: project_path)
        resolver = Resolvers::IssuesResolver
          .single.new(object: project, context: context)

        resolver.resolve(iid: iid)
      end
    end
  end
end
