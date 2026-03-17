# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'gitlab_quality/test_tooling'

module Gitlab
  module Rspec
    module Configurations
      class TestMetrics
        REQUIRED_CLICKHOUSE_ENV_VARS = %w[
          GLCI_DA_CLICKHOUSE_URL
          GLCI_CLICKHOUSE_METRICS_USERNAME
          GLCI_CLICKHOUSE_METRICS_PASSWORD
          GLCI_CLICKHOUSE_METRICS_DB
          GLCI_CLICKHOUSE_METRICS_TABLE
          GLCI_CLICKHOUSE_SHARED_DB
        ].freeze

        class << self
          def configure!(run_type = test_run_type)
            return unless ENV["CI"] && ENV["GLCI_EXPORT_TEST_METRICS"] == "true" && run_type

            RSpec.configure do |rspec_config|
              next if rspec_config.dry_run?

              GitlabQuality::TestTooling::TestMetricsExporter::Config.configure do |exporter_config|
                self.logger = exporter_config.logger

                if clickhouse_env_vars_present?
                  yield(exporter_config) if block_given?

                  exporter_config.run_type = run_type
                  exporter_config.custom_metrics_proc = custom_metrics_proc
                  exporter_config.clickhouse_config = clickhouse_config

                  rspec_config.add_formatter GitlabQuality::TestTooling::TestMetricsExporter::Formatter
                else
                  missing = REQUIRED_CLICKHOUSE_ENV_VARS.reject { |var| ENV[var] && !ENV[var].empty? }
                  logger.warn("Test metrics export is enabled but missing environment variables: #{missing.join(', ')}")
                end
              end
            end
          end

          private

          attr_writer :logger

          def logger
            @logger ||= Logger.new($stdout)
          end

          def clickhouse_env_vars_present?
            REQUIRED_CLICKHOUSE_ENV_VARS.all? { |var| ENV[var] && !ENV[var].empty? }
          end

          def owner_records
            @owner_records ||= GitlabQuality::TestTooling::CodeCoverage::ClickHouse::CategoryOwnersTable.new(
              database: ENV["GLCI_CLICKHOUSE_SHARED_DB"],
              url: clickhouse_url,
              username: clickhouse_username,
              password: clickhouse_password
            ).owner_records
          rescue StandardError => e
            logger.error("Failed to retrieve owner data: #{e}")
            @owner_records = {}
          end

          def clickhouse_config
            GitlabQuality::TestTooling::TestMetricsExporter::Config::ClickHouse.new(
              database: ENV["GLCI_CLICKHOUSE_METRICS_DB"],
              table_name: ENV["GLCI_CLICKHOUSE_METRICS_TABLE"],
              url: clickhouse_url,
              username: clickhouse_username,
              password: clickhouse_password
            )
          end

          def custom_metrics_proc
            proc do |example|
              feature_category = example.metadata[:feature_category]

              owners = if feature_category
                         owner_records.fetch(feature_category.to_s, {}).tap do |o|
                           logger.warn("Feature category '#{feature_category}' has no owner data") if o.empty?
                         end
                       else
                         logger.warn("Example '#{example.description}' missing feature category metadata.")
                         {}
                       end

              { pipeline_type: pipeline_type, ci_pipeline_id: ci_pipeline_id, **owners }
            end
          end

          def default_branch?
            ENV["CI_COMMIT_REF_NAME"] == ENV["CI_DEFAULT_BRANCH"]
          end

          def pipeline_type
            @pipeline_type ||= if default_branch? && ENV["SCHEDULE_TYPE"].present?
                                 "default_branch_scheduled_pipeline"
                               elsif default_branch?
                                 "default_branch_pipeline"
                               elsif ENV["CI_COMMIT_REF_NAME"]&.match?(/^[\d-]+-stable-ee$/)
                                 "stable_branch_pipeline"
                               elsif ENV["CI_MERGE_REQUEST_TARGET_BRANCH_NAME"]&.match?(/^[\d-]+-stable-ee$/)
                                 "backport_merge_request_pipeline"
                               elsif ENV["CI_MERGE_REQUEST_IID"].present?
                                 "merge_request_pipeline"
                               elsif ENV["CI_PIPELINE_SOURCE"] == "pipeline"
                                 "downstream_pipeline"
                               else
                                 "unknown"
                               end
          end

          def test_run_type
            @run_type ||= ENV["GLCI_TEST_METRICS_RUN_TYPE"]
          end

          def clickhouse_url
            ENV["GLCI_DA_CLICKHOUSE_URL"]
          end

          def clickhouse_username
            ENV["GLCI_CLICKHOUSE_METRICS_USERNAME"]
          end

          def clickhouse_password
            ENV["GLCI_CLICKHOUSE_METRICS_PASSWORD"]
          end

          def ci_pipeline_id
            (ENV["PARENT_PIPELINE_ID"] || ENV["CI_PIPELINE_ID"]).to_i
          end
        end
      end
    end
  end
end
