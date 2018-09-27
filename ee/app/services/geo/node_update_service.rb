module Geo
  class NodeUpdateService
    attr_reader :geo_node, :old_namespace_ids, :old_shards, :params

    def initialize(geo_node, params)
      @geo_node = geo_node
      @old_namespace_ids = geo_node.namespace_ids
      @old_shards = geo_node.selective_sync_shards

      @params = params.dup

      @params[:namespace_ids] = @params[:namespace_ids].to_s.split(',')
    end

    def execute
      return false unless geo_node.update(params)

      Geo::RepositoriesChangedEventStore.new(geo_node).create! if selective_sync_changed?

      true
    end

    private

    def selective_sync_changed?
      return false unless geo_node.secondary?

      geo_node.selective_sync_type_changed? ||
        selective_sync_by_namespaces_changed? ||
        selective_sync_by_shards_changed?
    end

    def selective_sync_by_namespaces_changed?
      return false unless geo_node.selective_sync_by_namespaces?

      geo_node.namespace_ids.any? && geo_node.namespace_ids != old_namespace_ids
    end

    def selective_sync_by_shards_changed?
      return false unless geo_node.selective_sync_by_shards?

      geo_node.selective_sync_shards.any? && geo_node.selective_sync_shards != old_shards
    end
  end
end
