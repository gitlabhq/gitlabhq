# frozen_string_literal: true

module QA
  module Support
    module Formatters
      # RSpec formatter to enhance metadata present in allure report
      # Following additional data is added:
      #   * quarantine issue links
      #   * failure issues search link
      #   * ci job link
      #   * flaky status and test pass rate
      #   * devops stage and group as epic and feature behaviour tags
      #
      class AllureMetadataFormatter < ::RSpec::Core::Formatters::BaseFormatter
        include Support::InfluxdbTools

        ::RSpec::Core::Formatters.register(
          self,
          :start,
          :example_finished
        )

        # Starts test run
        # Fetch flakiness data in mr pipelines to help identify unrelated flaky failures
        #
        # @param [RSpec::Core::Notifications::StartNotification] _start_notification
        # @return [void]
        def start(_start_notification)
          save_flaky_specs
          log(:debug, "Fetched #{flaky_specs.length} flaky testcases!")
        rescue StandardError => e
          log(:error, "Failed to fetch flaky spec data for report: #{e}")
          @flaky_specs = {}
        end

        # Finished example
        # Add additional metadata to report
        #
        # @param [RSpec::Core::Notifications::ExampleNotification] example_notification
        # @return [void]
        def example_finished(example_notification)
          example = example_notification.example

          add_quarantine_issue_link(example)
          add_failure_issues_link(example, example_notification)
          add_ci_job_link(example)
          set_flaky_status(example)
          set_behaviour_categories(example)
        end

        private

        # Add quarantine issue links
        #
        # @param [RSpec::Core::Example] example
        # @return [void]
        def add_quarantine_issue_link(example)
          issue_link = example.metadata.dig(:quarantine, :issue)

          return unless issue_link
          return example.issue('Quarantine issue', issue_link) if issue_link.is_a?(String)
          return issue_link.each { |link| example.issue('Quarantine issue', link) } if issue_link.is_a?(Array)
        rescue StandardError => e
          log(:error, "Failed to add quarantine issue link for example '#{example.description}', error: #{e}")
        end

        # Add failure issues link
        #
        # @param [RSpec::Core::Example] example
        # @return [void]
        def add_failure_issues_link(example, example_notification)
          return unless example.execution_result.status == :failed

          search_parameters = {
            sort: 'updated_desc',
            scope: 'all',
            state: 'opened'
          }.map { |key, value| "#{key}=#{value}" }.join('&')

          exception_message = example.exception.message || ""
          exception_message_lines = strip_ansi_codes(example_notification.message_lines) || []
          search_terms = {
            test_file_path: example.file_path.gsub('./qa/specs/features/', '').to_s,
            exception_message: exception_message_lines.empty? ? exception_message : exception_message_lines.join("\n")
          }.map { |_, value| "search=#{ERB::Util.url_encode(value)}" }.join('&')

          search_url = "https://gitlab.com/gitlab-org/gitlab/-/issues?#{search_parameters}&#{search_terms}"
          example.issue('Failure issues', search_url)
        rescue StandardError => e
          log(:error, "Failed to add failure issue link for example '#{example.description}', error: #{e}")
        end

        def strip_ansi_codes(strings)
          modified = Array(strings).map { |string| string.dup.gsub(/\x1b\[{1,2}[0-9;:?]*m/m, '') }
          modified.size == 1 ? modified[0] : modified
        end

        # Add ci job link
        #
        # @param [RSpec::Core::Example] example
        # @return [void]
        def add_ci_job_link(example)
          return unless Runtime::Env.running_in_ci?

          example.add_link(name: "Job(#{Runtime::Env.ci_job_name})", url: Runtime::Env.ci_job_url)
        rescue StandardError => e
          log(:error, "Failed to add ci job link for example '#{example.description}', error: #{e}")
        end

        # Mark test as flaky
        #
        # @param [RSpec::Core::Example] example
        # @return [void]
        def set_flaky_status(example)
          return unless flaky_specs.key?(example.metadata[:testcase]) && example.execution_result.status != :pending

          example.set_flaky
          log(:debug, "Setting spec as flaky because it's pass rate is below 98%")
        rescue StandardError => e
          log(:error, "Failed to add spec pass rate data for example '#{example.description}', error: #{e}")
        end

        # Add behaviour categories to report
        #
        # @param [RSpec::Core::Example] example
        # @return [void]
        def set_behaviour_categories(example)
          file_path = example.file_path.gsub('./qa/specs/features', '')
          devops_stage = file_path.match(%r{\d{1,2}_(\w+)/})&.captures&.first
          product_group = example.metadata[:product_group]

          example.epic(devops_stage) if devops_stage
          example.feature(product_group) if product_group
        end

        # Flaky specs with pass rate below 98%
        #
        # @return [Array]
        def flaky_specs
          @flaky_specs ||= influx_data.lazy.each_with_object({}) do |data, result|
            records = data.records

            runs = records.count
            failed = records.count { |r| r.values["status"] == "failed" }
            pass_rate = 100 - ((failed.to_f / runs) * 100)

            # Consider spec with a pass rate less than 98% as flaky
            result[records.last.values["testcase"]] = pass_rate if pass_rate < 98
          end.compact
        end

        alias_method :save_flaky_specs, :flaky_specs

        # Records of previous failures for runs of same type
        #
        # @return [Array]
        def influx_data
          return [] unless run_type

          query_api.query(query: <<~QUERY)
            from(bucket: "#{Support::InfluxdbTools::INFLUX_MAIN_TEST_METRICS_BUCKET}")
              |> range(start: -30d)
              |> filter(fn: (r) => r._measurement == "test-stats")
              |> filter(fn: (r) => r.run_type == "#{run_type}" and
                r.status != "pending" and
                r.quarantined == "false" and
                r._field == "id"
              )
              |> group(columns: ["testcase"])
          QUERY
        end

        # Print log message
        #
        # @param [Symbol] level
        # @param [String] message
        # @return [void]
        def log(level, message)
          QA::Runtime::Logger.public_send(level, "[Allure]: #{message}")
        end
      end
    end
  end
end
