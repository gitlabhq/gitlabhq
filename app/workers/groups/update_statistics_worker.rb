# frozen_string_literal: true

# Worker for updating group statistics.
module Groups
  class UpdateStatisticsWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    worker_resource_boundary :cpu

    feature_category :source_code_management
    idempotent!
    loggable_arguments 0, 1

    # group_id - The ID of the group for which to flush the cache.
    # statistics - An Array containing columns from NamespaceStatistics to
    #              refresh, if empty all columns will be refreshed
    def perform(group_id, statistics = [])
      group = Group.find_by_id(group_id)

      return unless group

      Groups::UpdateStatisticsService.new(group, statistics: statistics).execute
    end
  end
end
