# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncIndexes
      DEFAULT_INDEXES_PER_INVOCATION = 2

      def self.create_pending_indexes!(how_many: DEFAULT_INDEXES_PER_INVOCATION)
        PostgresAsyncIndex.to_create.ordered.limit(how_many).each do |async_index|
          IndexCreator.new(async_index).perform
        end
      end

      def self.drop_pending_indexes!(how_many: DEFAULT_INDEXES_PER_INVOCATION)
        PostgresAsyncIndex.to_drop.ordered.limit(how_many).each do |async_index|
          IndexDestructor.new(async_index).perform
        end
      end

      def self.execute_pending_actions!(how_many: DEFAULT_INDEXES_PER_INVOCATION)
        queue_ids = PostgresAsyncIndex.ordered.limit(how_many).pluck(:id)
        removal_actions = PostgresAsyncIndex.where(id: queue_ids).to_drop.ordered
        creation_actions = PostgresAsyncIndex.where(id: queue_ids).to_create.ordered

        removal_actions.each { |async_index| IndexDestructor.new(async_index).perform }
        creation_actions.each { |async_index| IndexCreator.new(async_index).perform }
      end
    end
  end
end
