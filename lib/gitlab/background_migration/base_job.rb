# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Simple base class for background migration job classes which are executed through the sidekiq queue.
    #
    # Any job class that inherits from the base class will have connection to the tracking database set on
    # initialization.
    class BaseJob
      def initialize(connection:)
        @connection = connection
      end

      def perform(*arguments)
        raise NotImplementedError, "subclasses of #{self.class.name} must implement #{__method__}"
      end

      private

      attr_reader :connection
    end
  end
end
