# frozen_string_literal: true

module Resolvers
  class NamespaceProjectsResolver < BaseResolver
    argument :include_subgroups, GraphQL::BOOLEAN_TYPE,
             required: false,
             default_value: false,
             description: 'Include also subgroup projects'

    argument :search, GraphQL::STRING_TYPE,
            required: false,
            default_value: nil,
            description: 'Search project with most similar names or paths'

    argument :sort, Types::Projects::NamespaceProjectSortEnum,
            required: false,
            default_value: nil,
            description: 'Sort projects by this criteria'

    type Types::ProjectType, null: true

    def resolve(include_subgroups:, sort:, search:)
      # The namespace could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` or the `full_path` of the namespace
      # to query for projects, so make sure it's loaded and not `nil` before continuing.
      return Project.none if namespace.nil?

      query = include_subgroups ? namespace.all_projects.with_route : namespace.projects.with_route

      return query unless search.present?

      if sort == :similarity
        query.sorted_by_similarity_desc(search, include_in_select: true).merge(Project.search(search))
      else
        query.merge(Project.search(search))
      end
    end

    def self.resolver_complexity(args, child_complexity:)
      complexity = super
      complexity + 10
    end

    private

    def namespace
      strong_memoize(:namespace) do
        object.respond_to?(:sync) ? object.sync : object
      end
    end
  end
end

Resolvers::NamespaceProjectsResolver.prepend_if_ee('::EE::Resolvers::NamespaceProjectsResolver')
