# frozen_string_literal: true

module Ci
  # This model represents a record in a shadow table of the main database's namespaces table.
  # It allows us to navigate the namespace hierarchy on the ci database without resorting to a JOIN.
  class NamespaceMirror < ApplicationRecord
    include FromUnion

    belongs_to :namespace
    has_many :project_mirrors, primary_key: :namespace_id, foreign_key: :namespace_id, inverse_of: :namespace_mirror

    # Resolves a single group and its descendants using the
    # `index_ci_namespace_mirrors_on_traversal_ids_unnest` covering index via the
    # `(traversal_ids[1..N]) IN (...)` form built by `contains_traversal_ids`, which
    # supports an index-only scan even for large subtrees
    # (see https://gitlab.com/gitlab-org/gitlab/-/issues/601877).
    #
    # Only a single id is supported: the prefix lookup anchors on one group's
    # traversal_ids, so it cannot express per-row ancestry containment for
    # multiple ids. Callers with several groups should invoke the scope per id.
    scope :by_group_and_descendants, ->(id) do
      raise ArgumentError, 'only a single id is supported' if id.is_a?(Enumerable)

      traversal_ids = by_namespace_id(id).pick(:traversal_ids)

      next none if traversal_ids.blank?

      contains_traversal_ids([traversal_ids])
    end

    scope :contains_traversal_ids, ->(traversal_ids) do
      mirrors = []

      traversal_ids.group_by(&:count).each do |columns_count, traversal_ids_group|
        columns = Array.new(columns_count) { |i| "(traversal_ids[#{i + 1}])" }
        pairs = traversal_ids_group.map do |ids|
          ids = ids.map { |id| Arel::Nodes.build_quoted(id).to_sql }
          "(#{ids.join(',')})"
        end

        # Create condition in format:
        # ((traversal_ids[1]),(traversal_ids[2])) IN ((1,2),(2,3))
        mirrors << Ci::NamespaceMirror.where("(#{columns.join(',')}) IN (#{pairs.join(',')})") # rubocop:disable GitlabSecurity/SqlInjection
      end

      self.from_union(mirrors)
    end

    scope :by_namespace_id, ->(namespace_id) { where(namespace_id: namespace_id) }

    class << self
      def sync!(event)
        namespace = event.namespace
        traversal_ids = namespace.self_and_ancestor_ids(hierarchy_order: :desc)

        upsert({ namespace_id: event.namespace_id, traversal_ids: traversal_ids }, unique_by: :namespace_id)
      end
    end
  end
end
