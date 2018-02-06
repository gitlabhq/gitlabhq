# Inspired by https://github.com/peek/peek-pg/blob/master/lib/peek/views/pg.rb
# PEEK_DB_CLIENT is a constant set in config/initializers/peek.rb
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
            # data[:cached] is only available starting from Rails 5.1.0
            # https://github.com/rails/rails/blob/v5.1.0/activerecord/lib/active_record/connection_adapters/abstract/query_cache.rb#L113
            # Before that, data[:name] was set to 'CACHE'
            # https://github.com/rails/rails/blob/v4.2.9/activerecord/lib/active_record/connection_adapters/abstract/query_cache.rb#L80
            unless data.fetch(:cached, data[:name] == 'CACHE')
              track_query(data[:sql].strip, data[:binds], start, finish)
            end
          end
        end
      end

      def track_query(raw_query, bindings, start, finish)
        duration = (finish - start) * 1000.0
        query_info = { duration: duration.round(3), sql: raw_query }

        PEEK_DB_CLIENT.query_details << query_info
      end
    end
  end
end
