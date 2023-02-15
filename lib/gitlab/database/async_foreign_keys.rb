# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncForeignKeys
      DEFAULT_ENTRIES_PER_INVOCATION = 2

      def self.validate_pending_entries!(how_many: DEFAULT_ENTRIES_PER_INVOCATION)
        PostgresAsyncForeignKeyValidation.ordered.limit(how_many).each do |record|
          ForeignKeyValidator.new(record).perform
        end
      end
    end
  end
end
