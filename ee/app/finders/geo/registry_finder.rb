module Geo
  class RegistryFinder
    attr_reader :current_node

    delegate :selective_sync?, to: :current_node, allow_nil: true

    def initialize(current_node: nil)
      @current_node = current_node
    end

    protected

    def use_legacy_queries?
      # Selective project replication adds a wrinkle to FDW
      # queries, so we fallback to the legacy version for now.
      !Gitlab::Geo.fdw? || selective_sync?
    end
  end
end
