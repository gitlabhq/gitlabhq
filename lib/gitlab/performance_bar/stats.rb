# frozen_string_literal: true

module Gitlab
  module PerformanceBar
    # This class fetches Peek stats stored in redis and logs them in a
    # structured log (so these can be then analyzed in Kibana)
    class Stats
      IGNORED_BACKTRACE_LOCATIONS = %w[
        ee/lib/ee/peek
        lib/peek
        lib/gitlab/database
      ].freeze

      def initialize(redis)
        @redis = redis
      end

      def process(id)
        data = request(id)
        return unless data

        log_sql_queries(id, data)
      rescue StandardError => err
        logger.error(message: "failed to process request id #{id}: #{err.message}")
      end

      private

      def request(id)
        # Peek gem stores request data under peek:requests:request_id key
        json_data = @redis.get("peek:requests:#{id}")
        Gitlab::Json.parse(json_data)
      end

      def log_sql_queries(id, data)
        queries_by_location(data).each do |location, queries|
          next unless location

          duration = queries.sum { |query| query['duration'].to_f }
          log_info = {
            method_path: "#{location[:filename]}:#{location[:method]}",
            filename: location[:filename],
            type: :sql,
            request_id: id,
            count: queries.count,
            duration_ms: duration
          }

          logger.info(log_info)
        end
      end

      def queries_by_location(data)
        return [] unless queries = data.dig('data', 'active-record', 'details')

        queries.group_by do |query|
          parse_backtrace(query['backtrace'])
        end
      end

      def parse_backtrace(backtrace)
        return unless backtrace_row = find_caller(backtrace)
        return unless match = /(?<filename>.*):(?<filenum>\d+):in `(?<method>.*)'/.match(backtrace_row)

        {
          filename: match[:filename],
          # filenum may change quite frequently with every change in the file,
          # because the intention is to aggregate these queries, we group
          # them rather by method name which should not change so frequently
          # filenum: match[:filenum].to_i,
          method: match[:method]
        }
      end

      def find_caller(backtrace)
        backtrace.find do |line|
          !line.start_with?(*IGNORED_BACKTRACE_LOCATIONS)
        end
      end

      def logger
        @logger ||= Gitlab::PerformanceBar::Logger.build
      end
    end
  end
end
