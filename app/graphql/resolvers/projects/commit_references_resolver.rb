# frozen_string_literal: true

module Resolvers
  module Projects
    class CommitReferencesResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      argument :commit_sha, GraphQL::Types::String,
        required: true,
        description: 'Project commit SHA identifier. For example, `287774414568010855642518513f085491644061`.'

      authorize :read_commit

      alias_method :project, :object

      calls_gitaly!

      type ::Types::CommitReferencesType, null: true

      def resolve(commit_sha:)
        authorized_find!(oid: commit_sha)
      end

      def find_object(oid:)
        project.repository.commit(oid)
      end
    end
  end
end
