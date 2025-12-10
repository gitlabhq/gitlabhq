# frozen_string_literal: true

require 'gitlab_quality/test_tooling'

module Gitlab
  module Rspec
    module Configurations
      class TestMetrics
        class << self
          def configure!(run_type = test_run_type)
            return unless ENV["CI"] && ENV["GLCI_EXPORT_TEST_METRICS"] == "true" && run_type

            RSpec.configure do |rspec_config|
              next if rspec_config.dry_run?

              GitlabQuality::TestTooling::TestMetricsExporter::Config.configure do |exporter_config|
                if clickhouse_url && clickhouse_username && clickhouse_password
                  yield(exporter_config) if block_given?

                  exporter_config.run_type = run_type
                  exporter_config.custom_metrics_proc = custom_metrics_proc(exporter_config.logger)
                  exporter_config.clickhouse_config = clickhouse_config

                  rspec_config.add_formatter GitlabQuality::TestTooling::TestMetricsExporter::Formatter
                else
                  exporter_config.logger.warn("Test metrics export is enabled but environment variables are not set!")
                end
              end
            end
          end

          private

          def owners_table
            @owners_table ||= GitlabQuality::TestTooling::CodeCoverage::ClickHouse::CategoryOwnersTable.new(
              database: ENV["GLCI_CLICKHOUSE_TEST_COVERAGE_DB"],
              url: clickhouse_url,
              username: clickhouse_username,
              password: clickhouse_password
            )
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

          def custom_metrics_proc(logger)
            proc do |example|
              feature_category = example.metadata[:feature_category]

              owners = begin
                feature_category ? owners_table.owners(feature_category.to_s) : {}
              rescue GitlabQuality::TestTooling::CodeCoverage::ClickHouse::CategoryOwnersTable::MissingMappingError
                logger.error("Example '#{example.location}' contains unknown feature_category '#{feature_category}'")
                {}
              rescue StandardError => e
                logger.error("Failed to fetch owners for feature category '#{feature_category}'")
                logger.error(e.message)
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
