# frozen_string_literal: true

module Resolvers
  module Repositories
    class RefCommitResolver < BaseResolver
      type Types::Repositories::CommitType, null: true

      def resolve(**_args)
        commit = object&.dereferenced_target
        return unless commit

        lazy_project = BatchLoader::GraphQL.for(commit.repository.gl_project_path).batch do |paths, loader|
          paths.each { |path| loader.call(path, Project.find_by_full_path(path)) }
        end

        ::Gitlab::Graphql::Lazy.with_value(lazy_project) do |project|
          ::Commit.new(commit, project) if project
        end
      end
    end
  end
end
