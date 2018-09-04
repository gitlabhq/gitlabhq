module Geo
  class RegistryFinder
    attr_reader :current_node

    delegate :selective_sync?, to: :current_node, allow_nil: true

    def initialize(current_node: nil)
      @current_node = current_node
    end

    protected

    # When this feature isn't present, FDW queries pull every row from the
    # remote database and perform aggregates locally, leading to surprisingly
    # slow COUNT queries on large tables. For more details, see this link:
    # https://www.enterprisedb.com/blog/postgresql-aggregate-push-down-postgresfdw
    def aggregate_pushdown_supported?
      Gitlab::Geo::Fdw.enabled? && Gitlab::Database.version.to_f >= 10.0
    end

    def use_legacy_queries?
      # Selective project replication adds a wrinkle to FDW
      # queries, so we fallback to the legacy version for now.
      !Gitlab::Geo::Fdw.enabled? || selective_sync?
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_inner_join_registry_ids(objects, registry_ids, klass, foreign_key: :id)
      return klass.none if registry_ids.empty?

      joined_relation = objects.joins(<<~SQL)
        INNER JOIN
        (VALUES #{registry_ids.map { |id| "(#{id})" }.join(',')})
        registry(id)
        ON #{klass.table_name}.#{foreign_key} = registry.id
      SQL

      joined_relation
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_left_outer_join_registry_ids(objects, registry_ids, klass)
      return objects if registry_ids.empty?

      joined_relation = objects.joins(<<~SQL)
        LEFT OUTER JOIN
        (VALUES #{registry_ids.map { |id| "(#{id}, 't')" }.join(',')})
         registry(id, registry_present)
         ON #{klass.table_name}.id = registry.id
      SQL

      joined_relation.where(registry: { registry_present: [nil, false] })
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
