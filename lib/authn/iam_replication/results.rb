# frozen_string_literal: true

module Authn
  module IamReplication
    # Outcomes a replicator returns. The values are logged, so changing one breaks log queries.
    module Results
      DELIVERED = :delivered
      SKIPPED = :skipped
      ERROR = :error
      UNSUPPORTED_SECRET_DIGEST = :unsupported_secret_digest
    end
  end
end
