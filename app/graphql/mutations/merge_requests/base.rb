module Mutations
  module MergeRequests
    class Base < BaseMutation
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include Mutations::ResolvesProject

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: "The project the merge request to mutate is in"

      argument :iid, GraphQL::ID_TYPE,
               required: true,
               description: "The iid of the merge request to mutate"

      field :merge_request,
            Types::MergeRequestType,
            null: true,
            description: "The merge request after mutation"

      authorize :update_merge_request

      private

      def find_object(project_path:, iid:)
        project = resolve_project(full_path: project_path)
        resolver = Resolvers::MergeRequestResolver.new(object: project, context: context)

        resolver.resolve(iid: iid)
      end
    end
  end
end
