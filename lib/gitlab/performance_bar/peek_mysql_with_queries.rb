# Inspired by https://github.com/peek/peek-mysql2/blob/master/lib/peek/views/mysql2.rb
module Gitlab
  module PerformanceBar
    module PeekMysqlWithQueries
      def queries
        ::Mysql2::Client.query_details
      end

      def results
        super.merge(queries: queries)
      end

      private

      def setup_subscribers
        super

        # Reset each counter when a new request starts
        before_request do
          ::Mysql2::Client.query_details = []
        end

        subscribe('sql.active_record') do |_, start, finish, _, data|
          if RequestStore.active? && RequestStore.store[:peek_enabled]
            track_query(data[:sql].strip, data[:binds], start, finish)
          end
        end
      end

      def track_query(raw_query, bindings, start, finish)
        query = Gitlab::Sherlock::Query.new(raw_query, start, finish)
        ::Mysql2::Client.query_details << query.formatted_query
      end
    end
  end
end
