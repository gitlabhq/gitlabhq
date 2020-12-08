# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class Updater
      def self.update!(...)
        new(...).update!
      end

      def initialize(event_result, from:, to:, klass:)
        @event_result = event_result
        @klass = klass
        @from = from
        @to = to
      end

      def update!
        @event_result.each do |event|
          event[@to] = items[event.delete(@from).to_i].first
        end
      end

      def result_ids
        @event_result.map { |event| event[@from] }
      end

      def items
        @items ||= @klass.find(result_ids).group_by { |item| item['id'] }
      end
    end
  end
end
