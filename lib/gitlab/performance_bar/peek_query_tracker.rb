# Inspired by https://github.com/peek/peek-pg/blob/master/lib/peek/views/pg.rb
module Gitlab
  module PerformanceBar
    module PeekQueryTracker
      def sorted_queries
        PEEK_DB_CLIENT.query_details
          .sort { |a, b| b[:duration] <=> a[:duration] }
      end

      def results
        super.merge(queries: sorted_queries)
      end

      private

      def setup_subscribers
        super

        # Reset each counter when a new request starts
        before_request do
          PEEK_DB_CLIENT.query_details = []
        end

        subscribe('sql.active_record') do |_, start, finish, _, data|
          if RequestStore.active? && RequestStore.store[:peek_enabled]
            track_query(data[:sql].strip, data[:binds], start, finish)
          end
        end
      end

      def track_query(raw_query, bindings, start, finish)
        query = Gitlab::Sherlock::Query.new(raw_query, start, finish)
        query_info = { duration: '%.3f' % query.duration, sql: query.formatted_query }

        PEEK_DB_CLIENT.query_details << query_info
      end
    end
  end
end
