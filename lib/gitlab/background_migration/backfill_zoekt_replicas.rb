# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Assigns all zoekt indices to a replica
    class BackfillZoektReplicas < BatchedMigrationJob
      feature_category :global_search

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillZoektReplicas.prepend_mod
