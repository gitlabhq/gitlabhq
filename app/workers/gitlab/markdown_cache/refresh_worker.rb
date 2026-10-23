# frozen_string_literal: true

module Gitlab
  module MarkdownCache
    class RefreshWorker
      include ApplicationWorker

      data_consistency :delayed
      feature_category :markdown
      urgency :low
      worker_resource_boundary :cpu
      loggable_arguments 0

      deduplicate :until_executing
      idempotent!

      concurrency_limit -> { 100 }

      defer_on_database_health_signal(:gitlab_main) do |job_args, schema, _tables|
        table_name = job_args.first.safe_constantize&.table_name
        next [schema, []] unless table_name

        [Gitlab::Database::GitlabSchema.table_schema!(table_name), [table_name]]
      end

      def perform(class_name, id)
        klass = class_name.safe_constantize
        return unless klass

        record = klass.primary_key_in([id]).take # rubocop:disable CodeReuse/ActiveRecord -- needed here.
        return if record.nil? || record.markdown_cache_current?

        record.refresh_markdown_cache!
      end
    end
  end
end
