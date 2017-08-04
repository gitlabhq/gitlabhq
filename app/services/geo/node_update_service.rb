module Geo
  class NodeUpdateService
    attr_reader :geo_node, :old_namespace_ids, :params

    def initialize(geo_node, params)
      @geo_node = geo_node
      @old_namespace_ids = geo_node.namespace_ids
      @params = params.slice(:url, :primary, :namespace_ids)
    end

    def execute
      return false unless geo_node.update(params)

      if geo_node.secondary? && namespaces_changed?(geo_node)
        Geo::RepositoriesChangedEventStore.new(geo_node).create
      end

      geo_node
    end

    private

    def namespaces_changed?(geo_node)
      geo_node.namespace_ids.any? && geo_node.namespace_ids != old_namespace_ids
    end
  end
end
