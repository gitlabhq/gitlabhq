module Gitlab
  module CycleAnalytics
    class StagingEventFetcher < BaseEventFetcher
      def initialize(*args)
        @projections = [build_table[:id]]
        @order = build_table[:created_at]

        super(*args)
      end

      def fetch
        Updater.update!(event_result, from: 'id', to: 'build', klass: ::Ci::Build)

        super
      end

      def events_query
        base_query.join(build_table).on(mr_metrics_table[:pipeline_id].eq(build_table[:commit_id]))

        super
      end

      private

      def allowed_ids
        nil
      end

      def serialize(event)
        AnalyticsBuildSerializer.new.represent(event['build'])
      end
    end
  end
end
