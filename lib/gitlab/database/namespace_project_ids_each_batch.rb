# frozen_string_literal: true

module Gitlab
  module Database
    # This class utilizes NamespaceEachBatch to return batches of project IDs.
    # It accepts a namespace_id and an optional resolver for narrowing the project IDs
    # returned to a subset filtered per batch.
    #
    # Usage:
    #
    # # To invoke, pass any group_id
    # Gitlab::Database::NamespaceProjectIdsEachBatch.new(group_id: 42).execute
    # => [1, 2, 3]
    #
    # # To invoke, pass any group_id and an optional resolver
    # resolver = ->(batch) { ProjectSetting.for_projects(batch).has_vulnerabilities.pluck_primary_key }
    # Gitlab::Database::NamespaceProjectIdsEachBatch.new(group_id: 42, resolver: resolver).execute
    # => [1, 3]
    #
    class NamespaceProjectIdsEachBatch
      def initialize(group_id:, resolver: nil, batch_size: 100)
        @group_id = group_id
        @resolver = resolver
        @batch_size = batch_size
      end

      def execute
        return [] unless @group_id

        subgroup_ids.flat_map do |sub_group_id|
          direct_project_ids_for(sub_group_id)
        end
      end

      def subgroup_ids
        cursor = { current_id: @group_id, depth: [@group_id] }
        iterator = NamespaceEachBatch.new(namespace_class: Group, cursor: cursor)

        group_ids = []

        iterator.each_batch(of: @batch_size) { |ids| group_ids += ids }

        group_ids
      end

      def direct_project_ids_for(sub_group_id)
        project_ids = []

        Project.in_namespace(sub_group_id).each_batch(of: @batch_size) do |batch|
          project_ids += if @resolver
                           @resolver.call(batch)
                         else
                           batch.pluck_primary_key
                         end
        end

        project_ids
      end
    end
  end
end
