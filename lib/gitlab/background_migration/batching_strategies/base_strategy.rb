# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module BatchingStrategies
      # Simple base class for batching strategy job classes.
      #
      # Any strategy class that inherits from the base class will have connection to the tracking database set on
      # initialization.
      class BaseStrategy
        def initialize(connection:)
          @connection = connection
        end

        def next_batch(*arguments)
          raise NotImplementedError,
            "#{self.class} does not implement #{__method__}"
        end

        private

        attr_reader :connection
      end
    end
  end
end
