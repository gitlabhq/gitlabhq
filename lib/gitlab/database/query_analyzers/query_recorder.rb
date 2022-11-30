# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class QueryRecorder < Base
        LOG_PATH = 'query_recorder/'

        class << self
          def raw?
            true
          end

          def enabled?
            # Only enable QueryRecorder in CI on database MRs or default branch
            ENV['CI_MERGE_REQUEST_LABELS']&.include?('database') ||
              (ENV['CI_COMMIT_REF_NAME'].present? && ENV['CI_COMMIT_REF_NAME'] == ENV['CI_DEFAULT_BRANCH'])
          end

          def analyze(sql)
            payload = {
              sql: sql
            }

            log_query(payload)
          end

          def log_file
            Rails.root.join(LOG_PATH, "#{ENV.fetch('CI_JOB_NAME_SLUG', 'rspec')}.ndjson")
          end

          private

          def log_query(payload)
            log_dir = Rails.root.join(LOG_PATH)

            # Create log directory if it does not exist since it is only created
            # ahead of time by certain CI jobs
            FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)

            log_line = "#{Gitlab::Json.dump(payload)}\n"

            File.write(log_file, log_line, mode: 'a')
          end
        end
      end
    end
  end
end
