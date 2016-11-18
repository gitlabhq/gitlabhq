module Gitlab
  module CycleAnalytics
    class Updater
      def self.update!(*args)
        new(*args).update!
      end

      def initialize(event_result, update_klass, update_key, column = nil)
        @event_result = event_result
        @update_klass = update_klass
        @update_key = update_key.to_s
        @column = column || "#{@update_key}_id"
      end

      def update!
        @event_result.each do |event|
          event[@update_key] = items[event.delete(@column).to_i].first
        end
      end

      def result_ids
        @event_result.map { |event| event[@column] }
      end

      def items
        @items ||= @update_klass.find(result_ids).group_by { |item| item['id'] }
      end
    end
  end
end
