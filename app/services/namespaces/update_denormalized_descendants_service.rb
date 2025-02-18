# frozen_string_literal: true

module Namespaces
  class UpdateDenormalizedDescendantsService
    include Gitlab::Utils::StrongMemoize

    NAMESPACE_TYPE_MAPPING = {
      'Project' => :all_project_ids,
      'Group' => :self_and_descendant_group_ids
    }.freeze

    def initialize(namespace_id:)
      @namespace_id = namespace_id
    end

    def execute
      Namespaces::Descendants.transaction do
        namespace_exists = Namespace.primary_key_in(namespace_id).exists?

        # Do not try to lock the namespace if it's already locked
        locked_namespace = Namespace.primary_key_in(namespace_id).lock('FOR UPDATE SKIP LOCKED').first # rubocop: disable CodeReuse/ActiveRecord -- this is a special service for updating records
        next if namespace_exists && locked_namespace.nil?

        # If there is another process updating the hierarchy, this query will return nil and we just
        # stop the processing.
        descendants = Namespaces::Descendants.primary_key_in(namespace_id).lock('FOR UPDATE SKIP LOCKED').first # rubocop: disable CodeReuse/ActiveRecord -- this is a special service for updating records
        next unless descendants

        if namespace_exists
          update_namespace_descendants(locked_namespace)
        else
          descendants.destroy
        end

        :processed
      end
    end

    private

    attr_reader :namespace_id

    def update_namespace_descendants(namespace)
      ids = collect_namespace_ids

      Namespaces::Descendants.upsert_with_consistent_data(
        namespace: namespace,
        self_and_descendant_group_ids: ids[:self_and_descendant_group_ids].sort,
        all_project_ids: Project.where(project_namespace_id: ids[:all_project_ids]).order(:id).pluck_primary_key # rubocop: disable CodeReuse/ActiveRecord -- Service specific record lookup
      )
    end

    def collect_namespace_ids
      denormalized_ids = { self_and_descendant_group_ids: [], all_project_ids: [] }

      iterator.each_batch do |ids|
        namespaces = Namespace.primary_key_in(ids).select(:id, :type)
        namespaces.each do |namespace|
          denormalized_attribute = NAMESPACE_TYPE_MAPPING[namespace.type]
          denormalized_ids[denormalized_attribute] << namespace.id if denormalized_attribute
        end
      end

      denormalized_ids
    end

    def iterator
      Gitlab::Database::NamespaceEachBatch
        .new(namespace_class: Namespace, cursor: { current_id: namespace_id, depth: [namespace_id] })
    end
  end
end
