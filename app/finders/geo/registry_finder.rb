module Geo
  class RegistryFinder
    attr_reader :current_node

    def initialize(current_node: nil)
      @current_node = current_node
    end

    protected

    def fdw?
      # Selective project replication adds a wrinkle to FDW
      # queries, so we fallback to the legacy version for now.
      Gitlab::Geo.fdw? && !selective_sync
    end

    def selective_sync
      current_node.restricted_project_ids
    end
  end
end
