# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class BaseEventFetcher
      include BaseQuery
      include BaseDataExtraction

      attr_reader :projections, :query, :stage, :order, :options

      MAX_EVENTS = 50

      def initialize(stage:, options:)
        @stage = stage
        @options = options
      end

      def fetch
        update_author!

        event_result.map do |event|
          serialize(event) if has_permission?(event['id'])
        end.compact
      end

      def order
        @order || default_order
      end

      private

      def update_author!
        return unless event_result.any? && event_result.first['author_id']

        Updater.update!(event_result, from: 'author_id', to: 'author', klass: User)
      end

      def event_result
        @event_result ||= ActiveRecord::Base.connection.exec_query(events_query.to_sql).to_a
      end

      def events_query
        diff_fn = subtract_datetimes_diff(base_query, options[:start_time_attrs], options[:end_time_attrs])

        base_query.project(extract_diff_epoch(diff_fn).as('total_time'), *projections).order(order.desc).take(MAX_EVENTS)
      end

      def default_order
        [options[:start_time_attrs]].flatten.first
      end

      def serialize(_event)
        raise NotImplementedError.new("Expected #{self.name} to implement serialize(event)")
      end

      def has_permission?(id)
        allowed_ids.nil? || allowed_ids.include?(id.to_i)
      end

      def allowed_ids
        @allowed_ids ||= allowed_ids_finder_class
          .new(options[:current_user], allowed_ids_source)
          .execute.where(id: event_result_ids).pluck(:id)
      end

      def event_result_ids
        event_result.map { |event| event['id'] }
      end

      def allowed_ids_source
        group ? { group_id: group.id, include_subgroups: true } : { project_id: project.id }
      end

      def serialization_context
        {}
      end
    end
  end
end
