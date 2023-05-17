# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncConstraints
      DEFAULT_ENTRIES_PER_INVOCATION = 2

      def self.validate_pending_entries!(how_many: DEFAULT_ENTRIES_PER_INVOCATION)
        PostgresAsyncConstraintValidation.ordered.limit(how_many).each do |record|
          AsyncConstraints::Validators.for(record).perform
        end
      end
    end
  end
end
