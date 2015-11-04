module Gitlab
  module Sherlock
    class Query
      attr_reader :id, :query, :started_at, :finished_at, :backtrace

      PREFIX_NEWLINE = /
        \s+(FROM
          |(LEFT|RIGHT)?INNER\s+JOIN
          |(LEFT|RIGHT)?OUTER\s+JOIN
          |WHERE
          |AND
          |GROUP\s+BY
          |ORDER\s+BY
          |LIMIT
          |OFFSET)\s+
      /ix

      def self.new_with_bindings(query, bindings, started_at, finished_at)
        bindings.each_with_index do |(column, value), index|
          quoted_value = ActiveRecord::Base.connection.quote(value)

          query = query.gsub("$#{index + 1}", quoted_value)
        end

        new(query, started_at, finished_at)
      end

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

      def duration
        @duration ||= (@finished_at - @started_at) * 1000.0
      end

      def to_param
        @id
      end

      def formatted_query
        @formatted_query ||= format_sql(@query)
      end

      def last_application_frame
        @last_application_frame ||= @backtrace.find(&:application?)
      end

      def application_backtrace
        @application_backtrace ||= @backtrace.select(&:application?)
      end

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
        if Gitlab::Database.postgresql?
          explain = "EXPLAIN ANALYZE #{query};"
        else
          explain = "EXPLAIN #{query};"
        end

        ActiveRecord::Base.connection.execute(explain)
      end

      def format_sql(query)
        query.each_line.
          map { |line| line.strip }.
          join("\n").
          gsub(PREFIX_NEWLINE) { "\n#{$1} " }
      end
    end
  end
end
