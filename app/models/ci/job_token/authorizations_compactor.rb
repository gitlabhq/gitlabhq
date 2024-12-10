# frozen_string_literal: true

module Ci
  module JobToken
    class AuthorizationsCompactor
      attr_reader :allowlist_groups, :allowlist_projects

      UnexpectedCompactionEntry = Class.new(StandardError)
      RedundantCompactionEntry = Class.new(StandardError)

      def initialize(project_id)
        @project_id = project_id
        @allowlist_groups = []
        @allowlist_projects = []
      end

      def origin_project_traversal_ids
        @origin_project_traversal_ids ||= begin
          origin_project_traversal_ids = []
          origin_project_id_batches = []

          # Collecting id batches to avoid cross-database transactions.
          Ci::JobToken::Authorization.where(
            accessed_project_id: @project_id
          ).each_batch(column: :origin_project_id) do |batch|
            origin_project_id_batches << batch.pluck(:origin_project_id) # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- pluck limited by batch size
          end

          origin_project_id_batches.each do |batch|
            projects = Project.where(id: batch)
            origin_project_traversal_ids += projects.map { |p| p.project_namespace.traversal_ids }
          end

          origin_project_traversal_ids
        end
      end

      def compact(limit)
        compacted_traversal_ids = Gitlab::Utils::TraversalIdCompactor.compact(origin_project_traversal_ids, limit)

        Gitlab::Utils::TraversalIdCompactor.validate!(origin_project_traversal_ids, compacted_traversal_ids)

        namespace_ids = compacted_traversal_ids.map(&:last)
        namespaces = Namespace.where(id: namespace_ids)

        namespaces.each do |namespace|
          if namespace.project_namespace?
            @allowlist_projects << namespace.project
          else
            @allowlist_groups << namespace
          end
        end
      end
    end
  end
end
