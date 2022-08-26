# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module BatchingStrategies
      # Used to apply additional filters to the batching table, migrated to
      # use BatchedMigrationJob#filter_batch with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93771
      class BackfillProjectStatisticsWithContainerRegistrySizeBatchingStrategy < PrimaryKeyBatchingStrategy
      end
    end
  end
end
