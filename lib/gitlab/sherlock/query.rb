module Gitlab
  module Sherlock
    class Query
      attr_reader :id, :query, :started_at, :finished_at, :backtrace

      # SQL identifiers that should be prefixed with newlines.
      PREFIX_NEWLINE = %r{
        \s+(FROM
          |(LEFT|RIGHT)?INNER\s+JOIN
          |(LEFT|RIGHT)?OUTER\s+JOIN
          |WHERE
          |AND
          |GROUP\s+BY
          |ORDER\s+BY
          |LIMIT
          |OFFSET)\s+}ix # Vim indent breaks when this is on a newline :<

      # Creates a new Query using a String and a separate Array of bindings.
      #
      # query - A String containing a SQL query, optionally with numeric
      #         placeholders (`$1`, `$2`, etc).
      #
      # bindings - An Array of ActiveRecord columns and their values.
      # started_at - The start time of the query as a Time-like object.
      # finished_at - The completion time of the query as a Time-like object.
      #
      # Returns a new Query object.
      def self.new_with_bindings(query, bindings, started_at, finished_at)
        bindings.each_with_index do |(_, value), index|
          quoted_value = ActiveRecord::Base.connection.quote(value)

          query = query.gsub("$#{index + 1}", quoted_value)
        end

        new(query, started_at, finished_at)
      end

      # query - The SQL query as a String (without placeholders).
      # started_at - The start time of the query as a Time-like object.
      # finished_at - The completion time of the query as a Time-like object.
      def initialize(query, started_at, finished_at)
        @id = SecureRandom.uuid
        @query = query
        @started_at = started_at
        @finished_at = finished_at
        @backtrace = caller_locations.map do |loc|
          Location.from_ruby_location(loc)
        end

        unless @query.end_with?(';')
          @query += ';'
        end
      end

      # Returns the query duration in milliseconds.
      def duration
        @duration ||= (@finished_at - @started_at) * 1000.0
      end

      def to_param
        @id
      end

      # Returns a human readable version of the query.
      def formatted_query
        @formatted_query ||= format_sql(@query)
      end

      # Returns the last application frame of the backtrace.
      def last_application_frame
        @last_application_frame ||= @backtrace.find(&:application?)
      end

      # Returns an Array of application frames (excluding Gems and the likes).
      def application_backtrace
        @application_backtrace ||= @backtrace.select(&:application?)
      end

      # Returns the query plan as a String.
      def explain
        unless @explain
          ActiveRecord::Base.connection.transaction do
            @explain = raw_explain(@query).values.flatten.join("\n")

            # Roll back any queries that mutate data so we don't mess up
            # anything when running explain on an INSERT, UPDATE, DELETE, etc.
            raise ActiveRecord::Rollback
          end
        end

        @explain
      end

      private

      def raw_explain(query)
        explain =
          if Gitlab::Database.postgresql?
            "EXPLAIN ANALYZE #{query};"
          else
            "EXPLAIN #{query};"
          end

        ActiveRecord::Base.connection.execute(explain)
      end

      def format_sql(query)
        query.each_line
          .map { |line| line.strip }
          .join("\n")
          .gsub(PREFIX_NEWLINE) { "\n#{$1} " }
      end
    end
  end
end
