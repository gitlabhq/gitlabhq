# frozen_string_literal: true

module Gitlab
  module PolicyStore
    # Injection seam for the Policy Store. Swapping `repository` for a different
    # Gitlab::PolicyStore::Ports::PolicyRepository implementation (e.g. a
    # gRPC client to an extracted service) is the only change required to move
    # the storage layer out of the monolith.
    Configuration = Struct.new(:repository)
  end
end
