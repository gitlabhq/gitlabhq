# frozen_string_literal: true

module Resolvers
  class LastCommitResolver < BaseResolver
    type Types::Repositories::CommitType, null: true

    calls_gitaly!

    argument :path, GraphQL::Types::String,
      required: false,
      description: 'Path to get the last commit for. Default value is the root of the repository.'

    argument :ref, GraphQL::Types::String,
      required: false,
      description: 'Commit ref to get the last commit for. Default value is HEAD.'

    argument :ref_type, Types::RefTypeEnum,
      required: false,
      description: 'Type of ref.'

    # "container" will either be a Repository or a Tree, depending on which version of the
    # path_last_commit.query.graphql query triggered this resolver.
    alias_method :container, :object

    def resolve(**args)
      repo = container.is_a?(Tree) ? container.repository : container

      ref = args[:ref]
      ref = container.sha if container.respond_to?(:sha)

      path = args[:path]
      path = container.path if container.respond_to?(:path)

      ref_type = args[:ref_type]
      ref_type = container.ref_type if container.respond_to?(:ref_type)

      # Set the default here instead of in the argument definition. This allows us
      # to extract the path correctly from "args" or "container".
      path = '' if path.nil?

      # Ensure merge commits can be returned by sending nil to Gitaly instead of '/'
      path = path == '/' ? nil : path
      commit = Gitlab::Git::Commit.last_for_path(repo,
        ExtractsRef::RefExtractor.qualify_ref(ref, ref_type), path, literal_pathspec: true)

      ::Commit.new(commit, repo.project) if commit
    end
  end
end
