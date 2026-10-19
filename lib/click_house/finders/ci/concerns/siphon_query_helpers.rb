# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module Finders
    module Ci
      module Concerns
        module SiphonQueryHelpers
          private

          # Siphon stores traversal_path with the leading organization_id.
          def container_condition(query, namespace_or_project)
            if namespace_or_project.is_a?(Project)
              query[:traversal_path].eq(namespace_or_project.project_namespace.traversal_path(with_organization: true))
            else
              path = namespace_or_project.traversal_path(with_organization: true)
              query.func('startsWith', [query[:traversal_path], query.quote(path)])
            end
          end

          def joined_alias?(query, alias_name)
            query.manager.join_sources.any? do |join|
              source = join.left
              source.is_a?(Arel::Nodes::TableAlias) && source.right.to_s == alias_name
            end
          end
        end
      end
    end
  end
end
