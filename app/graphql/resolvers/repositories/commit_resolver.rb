# frozen_string_literal: true

module Resolvers
  module Repositories
    class CommitResolver < BaseResolver
      type Types::Repositories::CommitType, null: true

      argument :ref,
        GraphQL::Types::String,
        required: true,
        description: "Commit reference (SHA, branch name, or tag name)."

      calls_gitaly!

      alias_method :repository, :object

      def resolve(ref:)
        repository.commit(ref)
      end
    end
  end
end
