# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class ReindexProjectElasticZoektData < BatchedMigrationJob
      feature_category :global_search

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::ReindexProjectElasticZoektData.prepend_mod
