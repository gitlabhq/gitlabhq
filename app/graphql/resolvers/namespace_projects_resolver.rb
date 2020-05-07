# frozen_string_literal: true

module Resolvers
  class NamespaceProjectsResolver < BaseResolver
    argument :include_subgroups, GraphQL::BOOLEAN_TYPE,
             required: false,
             default_value: false,
             description: 'Include also subgroup projects'

    type Types::ProjectType, null: true

    def resolve(include_subgroups:)
      # The namespace could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` or the `full_path` of the namespace
      # to query for projects, so make sure it's loaded and not `nil` before continuing.
      namespace = object.respond_to?(:sync) ? object.sync : object
      return Project.none if namespace.nil?

      if include_subgroups
        namespace.all_projects.with_route
      else
        namespace.projects.with_route
      end
    end

    def self.resolver_complexity(args, child_complexity:)
      complexity = super
      complexity + 10
    end
  end
end

Resolvers::NamespaceProjectsResolver.prepend_if_ee('::EE::Resolvers::NamespaceProjectsResolver')
