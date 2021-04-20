# frozen_string_literal: true

module Gitlab
  module QueryLimiting
    class Transaction
      THREAD_KEY = :__gitlab_query_counts_transaction

      attr_accessor :count

      # The name of the action (e.g. `UsersController#show`) that is being
      # executed.
      attr_accessor :action

      # The maximum number of SQL queries that can be executed in a request. For
      # the sake of keeping things simple we hardcode this value here, it's not
      # supposed to be changed very often anyway.
      THRESHOLD = 100
      LOG_THRESHOLD = THRESHOLD * 1.5

      # Error that is raised whenever exceeding the maximum number of queries.
      ThresholdExceededError = Class.new(StandardError)

      def self.current
        Thread.current[THREAD_KEY]
      end

      # Starts a new transaction and returns it and the blocks' return value.
      #
      # Example:
      #
      #     transaction, retval = Transaction.run do
      #       10
      #     end
      #
      #     retval # => 10
      def self.run
        transaction = new
        Thread.current[THREAD_KEY] = transaction

        [transaction, yield]
      ensure
        Thread.current[THREAD_KEY] = nil
      end

      def initialize
        @action = nil
        @count = 0
        @sql_executed = []
      end

      # Sends a notification based on the number of executed SQL queries.
      def act_upon_results
        return unless threshold_exceeded?

        error = ThresholdExceededError.new(error_message)

        raise(error) if raise_error?
      end

      def increment
        @count += 1 if enabled?
      end

      def executed_sql(sql)
        @sql_executed << sql if @count <= LOG_THRESHOLD
      end

      def raise_error?
        Rails.env.test?
      end

      def threshold_exceeded?
        count > THRESHOLD
      end

      def error_message
        header = 'Too many SQL queries were executed'
        header = "#{header} in #{action}" if action
        msg = "a maximum of #{THRESHOLD} is allowed but #{count} SQL queries were executed"
        log = @sql_executed.each_with_index.map { |sql, i| "#{i}: #{sql}" }.join("\n").presence
        ellipsis = '...' if @count > LOG_THRESHOLD

        ["#{header}: #{msg}", log, ellipsis].compact.join("\n")
      end

      def enabled?
        ::Gitlab::QueryLimiting.enabled?
      end
    end
  end
end
