# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class QueryRecorder < Base
        LOG_FILE = 'rspec/query_recorder.ndjson'

        class << self
          def raw?
            true
          end

          def enabled?
            # Only enable QueryRecorder in CI
            ENV['CI'].present?
          end

          def analyze(sql)
            payload = {
              sql: sql
            }

            log_query(payload)
          end

          private

          def log_query(payload)
            log_path = Rails.root.join(LOG_FILE)
            log_dir = File.dirname(log_path)

            # Create log directory if it does not exist since it is only created
            # ahead of time by certain CI jobs
            FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)

            log_line = "#{Gitlab::Json.dump(payload)}\n"

            File.write(log_path, log_line, mode: 'a')
          end
        end
      end
    end
  end
end
