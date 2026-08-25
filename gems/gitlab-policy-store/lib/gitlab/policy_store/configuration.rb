# frozen_string_literal: true

module Gitlab
  module PolicyStore
    # Injection seam for the Policy Store. Swapping `repository` (a
    # Gitlab::PolicyStore::Ports::PolicyRepository) or `evaluation_recorder` (a
    # Gitlab::PolicyStore::Ports::EvaluationRecorder) for a different
    # implementation (e.g. a gRPC client to an extracted service) is the only
    # change required to move the storage layer out of the monolith.
    Configuration = Struct.new(:repository, :evaluation_recorder)
  end
end
