# frozen_string_literal: true

module Ci
  module JobToken
    class AuthorizationsCompactor
      include Gitlab::Utils::StrongMemoize

      attr_reader :allowlist_groups, :allowlist_projects

      Error = Class.new(StandardError)

      def initialize(project)
        @project = project
        @allowlist_groups = []
        @allowlist_projects = []
      end

      def origin_project_traversal_ids
        @origin_project_traversal_ids ||= begin
          origin_project_traversal_ids = []
          origin_project_id_batches = []

          # Collecting id batches to avoid cross-database transactions.
          Ci::JobToken::Authorization.where(
            accessed_project_id: @project.id
          ).each_batch(column: :origin_project_id) do |batch|
            origin_project_id_batches << batch.pluck(:origin_project_id) # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- pluck limited by batch size
          end

          origin_project_id_batches.each do |batch|
            projects = Project.where(id: batch).includes(:project_namespace)
            origin_project_traversal_ids += projects.filter_map do |p|
              p.project_namespace.traversal_ids unless path_already_allowlisted?(p.project_namespace.traversal_ids)
            end
          end

          origin_project_traversal_ids
        end
      end

      def compact(requested_limit)
        limit = requested_limit - existing_links_traversal_ids.count
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

      rescue Gitlab::Utils::TraversalIdCompactor::CompactionLimitCannotBeAchievedError,
        Gitlab::Utils::TraversalIdCompactor::RedundantCompactionEntry,
        Gitlab::Utils::TraversalIdCompactor::UnexpectedCompactionEntry => error

        raise Error, error.class.name.demodulize
      end

      def path_already_allowlisted?(namespace_path)
        existing_links_traversal_ids.any? do |existing_links_traversal_id|
          namespace_path.size >= existing_links_traversal_id.size &&
            namespace_path.first(existing_links_traversal_id.size) == existing_links_traversal_id
        end
      end

      def existing_links_traversal_ids
        allowlist = Ci::JobToken::Allowlist.new(@project)
        allowlist.group_link_traversal_ids + allowlist.project_link_traversal_ids
      end
      strong_memoize_attr :existing_links_traversal_ids
    end
  end
end
