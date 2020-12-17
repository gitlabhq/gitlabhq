# frozen_string_literal: true

module Gitlab
  module PerformanceBar
    # This class fetches Peek stats stored in redis and logs them in a
    # structured log (so these can be then analyzed in Kibana)
    class Stats
      def initialize(redis)
        @redis = redis
      end

      def process(id)
        data = request(id)
        return unless data

        log_sql_queries(id, data)
      rescue => err
        logger.error(message: "failed to process request id #{id}: #{err.message}")
      end

      private

      def request(id)
        # Peek gem stores request data under peek:requests:request_id key
        json_data = @redis.get("peek:requests:#{id}")
        Gitlab::Json.parse(json_data)
      end

      def log_sql_queries(id, data)
        return [] unless queries = data.dig('data', 'active-record', 'details')

        queries.each do |query|
          next unless location = parse_backtrace(query['backtrace'])

          log_info = location.merge(
            type: :sql,
            request_id: id,
            duration_ms: query['duration'].to_f
          )

          logger.info(log_info)
        end
      end

      def parse_backtrace(backtrace)
        return unless match = /(?<filename>.*):(?<filenum>\d+):in `(?<method>.*)'/.match(backtrace.first)

        {
          filename: match[:filename],
          filenum: match[:filenum].to_i,
          method: match[:method]
        }
      end

      def logger
        @logger ||= Gitlab::PerformanceBar::Logger.build
      end
    end
  end
end
