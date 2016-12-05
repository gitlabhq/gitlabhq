module Gitlab
  module CycleAnalytics
    class BaseEventFetcher
      include MetricsTables

      attr_reader :projections, :query, :stage, :order

      def initialize(fetcher:, options:, stage:)
        @fetcher = fetcher
        @project = fetcher.project
        @options = options
        @stage = stage
      end

      def fetch
        update_author!

        event_result.map do |event|
          serialize(event) if has_permission?(event['id'])
        end.compact
      end

      def custom_query(_base_query); end

      private

      def update_author!
        return unless event_result.any? && event_result.first['author_id']

        Updater.update!(event_result, from: 'author_id', to: 'author', klass: User)
      end

      def event_result
        @event_result ||= @fetcher.events.to_a
      end

      def serialize(_event)
        raise NotImplementedError.new("Expected #{self.name} to implement serialize(event)")
      end

      def has_permission?(id)
        allowed_ids.nil? || allowed_ids.include?(id.to_i)
      end

      def allowed_ids
        nil
      end

      def event_result_ids
        event_result.map { |event| event['id'] }
      end
    end
  end
end
