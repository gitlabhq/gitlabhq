# frozen_string_literal: true

module ClickHouse
  class RebuildMaterializedViewCronWorker
    include ApplicationWorker
    include ClickHouseWorker
    include Gitlab::ExclusiveLeaseHelpers

    idempotent!
    queue_namespace :cronjob
    data_consistency :delayed
    worker_has_external_dependencies! # the worker interacts with a ClickHouse database
    feature_category :value_stream_management

    MATERIALIZED_VIEWS = [
      {
        view_name: 'contributions_mv',
        view_table_name: 'contributions',
        tmp_view_name: 'tmp_contributions_mv',
        tmp_view_table_name: 'tmp_contributions',
        source_table_name: 'events'
      }.freeze
    ].freeze

    def perform
      connection = ClickHouse::Connection.new(:main)
      ClickHouse::RebuildMaterializedViewService
        .new(connection: connection, state: MATERIALIZED_VIEWS.first)
        .execute
    end
  end
end
