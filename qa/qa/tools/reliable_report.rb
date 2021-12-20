# frozen_string_literal: true

require_relative "../../qa"

require "influxdb-client"
require "terminal-table"
require "slack-notifier"
require "colorize"

module QA
  module Tools
    class ReliableReport
      include Support::API

      # Project for report creation: https://gitlab.com/gitlab-org/gitlab
      PROJECT_ID = 278964

      def initialize(range)
        @range = range
        @influxdb_bucket = "e2e-test-stats"
        @slack_channel = "#quality-reports"
        @influxdb_url = ENV["QA_INFLUXDB_URL"] || raise("Missing QA_INFLUXDB_URL env variable")
        @influxdb_token = ENV["QA_INFLUXDB_TOKEN"] || raise("Missing QA_INFLUXDB_TOKEN env variable")
      end

      # Run reliable reporter
      #
      # @param [Integer] range amount of days for results range
      # @param [String] report_in_issue_and_slack
      # @return [void]
      def self.run(range: 14, report_in_issue_and_slack: "false")
        reporter = new(range)

        reporter.print_report
        reporter.report_in_issue_and_slack if report_in_issue_and_slack == "true"
      rescue StandardError => e
        reporter.notify_failure(e)
        raise(e)
      end

      # Print top stable specs
      #
      # @return [void]
      def print_report
        puts "#{stable_summary_table}\n\n"
        stable_results_tables.each { |stage, table| puts "#{table}\n\n" }
        return puts("No unstable reliable tests present!".colorize(:yellow)) if unstable_reliable_test_runs.empty?

        puts "#{unstable_summary_table}\n\n"
        unstable_reliable_results_tables.each { |stage, table| puts "#{table}\n\n" }
      end

      # Create report issue
      #
      # @return [void]
      def report_in_issue_and_slack
        puts "Creating report".colorize(:green)
        response = post(
          "#{gitlab_api_url}/projects/#{PROJECT_ID}/issues",
          { title: "Reliable spec report", description: report_issue_body, labels: "Quality,test" },
          headers: { "PRIVATE-TOKEN" => gitlab_access_token }
        )
        web_url = parse_body(response)[:web_url]
        puts "Created report issue: #{web_url}"

        puts "Sending slack notification".colorize(:green)
        notifier.post(
          icon_emoji: ":tanuki-protect:",
          text: <<~TEXT
            ```#{stable_summary_table}```
            ```#{unstable_summary_table}```

            #{web_url}
          TEXT
        )
        puts "Done!"
      end

      # Notify failure
      #
      # @param [StandardError] error
      # @return [void]
      def notify_failure(error)
        notifier.post(
          text: "Reliable reporter failed to create report. Error: ```#{error}```",
          icon_emoji: ":sadpanda:"
        )
      end

      private

      attr_reader :range, :influxdb_bucket, :slack_channel, :influxdb_url, :influxdb_token

      # Markdown formatted report issue body
      #
      # @return [String]
      def report_issue_body
        execution_interval = "(#{Date.today - range} - #{Date.today})"

        issue = []
        issue << "[[_TOC_]]"
        issue << "# Candidates for promotion to reliable #{execution_interval}"
        issue << "```\n#{stable_summary_table}\n```"
        issue << results_markdown(stable_results_tables)
        return issue.join("\n\n") if unstable_reliable_test_runs.empty?

        issue << "# Reliable specs with failures #{execution_interval}"
        issue << "```\n#{unstable_summary_table}\n```"
        issue << results_markdown(unstable_reliable_results_tables)
        issue.join("\n\n")
      end

      # Stable spec summary table
      #
      # @return [Terminal::Table]
      def stable_summary_table
        @stable_summary_table ||= terminal_table(
          rows: stable_test_runs.map { |stage, specs| [stage, specs.length] },
          title: "Stable spec summary for past #{range} days".ljust(50),
          headings: %w[STAGE COUNT]
        )
      end

      # Unstable reliable summary table
      #
      # @return [Terminal::Table]
      def unstable_summary_table
        @unstable_summary_table ||= terminal_table(
          rows: unstable_reliable_test_runs.map { |stage, specs| [stage, specs.length] },
          title: "Unstable spec summary for past #{range} days".ljust(50),
          headings: %w[STAGE COUNT]
        )
      end

      # Result tables for stable specs
      #
      # @return [Hash]
      def stable_results_tables
        @stable_results ||= results_tables(:stable)
      end

      # Result table for unstable specs
      #
      # @return [Hash]
      def unstable_reliable_results_tables
        @unstable_results ||= results_tables(:unstable)
      end

      # Markdown formatted tables
      #
      # @param [Hash] results
      # @return [String]
      def results_markdown(results)
        results.map do |stage, table|
          <<~STAGE.strip
            ## #{stage}

            <details>
            <summary>Executions table</summary>

            ```
            #{table}
            ```

            </details>
          STAGE
        end.join("\n\n")
      end

      # Results table
      #
      # @param [Symbol] type result type - :stable, :unstable
      # @return [Hash<Symbol, Terminal::Table>]
      def results_tables(type)
        (type == :stable ? stable_test_runs : unstable_reliable_test_runs).to_h do |stage, specs|
          headings = ["name", "runs", "failures", "failure rate"]

          [stage, terminal_table(
            rows: specs.map { |k, v| [name_column(k, v[:file]), *table_params(v.values)] },
            title: "Top #{type} specs in '#{stage}' stage for past #{range} days",
            headings: headings.map(&:upcase)
          )]
        end
      end

      # Stable specs
      #
      # @return [Hash]
      def stable_test_runs
        @top_stable ||= begin
          stable_specs = test_runs(reliable: false).transform_values do |specs|
            specs
              .reject { |k, v| v[:failure_rate] != 0 }
              .sort_by { |k, v| -v[:runs] }
              .to_h
          end

          stable_specs.reject { |k, v| v.empty? }
        end
      end

      # Unstable reliable specs
      #
      # @return [Hash]
      def unstable_reliable_test_runs
        @top_unstable_reliable ||= begin
          unstable = test_runs(reliable: true).transform_values do |specs|
            specs
              .reject { |k, v| v[:failure_rate] == 0 }
              .sort_by { |k, v| -v[:failure_rate] }
              .to_h
          end

          unstable.reject { |k, v| v.empty? }
        end
      end

      # Terminal table for result formatting
      #
      # @return [Terminal::Table]
      def terminal_table(rows:, headings:, title: nil)
        Terminal::Table.new(
          headings: headings,
          style: { all_separators: true },
          title: title,
          rows: rows
        )
      end

      # Spec parameters for table row
      #
      # @param [Array] parameters
      # @return [Array]
      def table_params(parameters)
        [*parameters[1..2], "#{parameters.last}%"]
      end

      # Name column value
      #
      # @param [String] name
      # @param [String] file
      # @return [String]
      def name_column(name, file)
        spec_name = name.length > 150 ? "#{name} ".scan(/.{1,150} /).map(&:strip).join("\n") : name
        name_line = "name: '#{spec_name}'"
        file_line = "file: '#{file}'"

        "#{name_line}\n#{file_line.ljust(160)}"
      end

      # Test executions grouped by name
      #
      # @param [Boolean] reliable
      # @return [Hash<String, Hash>]
      def test_runs(reliable:)
        puts("Fetching data on #{reliable ? 'reliable ' : ''}test execution for past #{range} days\n".colorize(:green))

        all_runs = query_api.query(query: query(reliable)).values
        all_runs.each_with_object(Hash.new { |hsh, key| hsh[key] = {} }) do |table, result|
          records = table.records
          # skip specs that executed less time than defined by range
          # offset 1 day due to how schedulers are configured and first run can be 1 day later
          next if (Date.today - Date.parse(records.first.values["_time"])).to_i < (range - 1)

          last_record = records.last.values
          name = last_record["name"]
          file = last_record["file_path"].split("/").last
          stage = last_record["stage"] || "unknown"

          runs = records.count
          failed = records.count { |r| r.values["status"] == "failed" }
          failure_rate = (failed.to_f / runs.to_f) * 100

          result[stage][name] = {
            file: file,
            runs: runs,
            failed: failed,
            failure_rate: failure_rate == 0 ? failure_rate.round(0) : failure_rate.round(2)
          }
        end
      end

      # Flux query
      #
      # @param [Boolean] reliable
      # @return [String]
      def query(reliable)
        <<~QUERY
          from(bucket: "#{influxdb_bucket}")
            |> range(start: -#{range}d)
            |> filter(fn: (r) => r._measurement == "test-stats")
            |> filter(fn: (r) => r.run_type == "staging-full" or
              r.run_type == "staging-sanity" or
              r.run_type == "staging-sanity-no-admin" or
              r.run_type == "production-full" or
              r.run_type == "production-sanity" or
              r.run_type == "package-and-qa" or
              r.run_type == "nightly"
            )
            |> filter(fn: (r) => r.status != "pending" and
              r.merge_request == "false" and
              r.quarantined == "false" and
              r.reliable == "#{reliable}" and
              r._field == "id"
            )
            |> group(columns: ["name"])
        QUERY
      end

      # Query client
      #
      # @return [QueryApi]
      def query_api
        @query_api ||= influx_client.create_query_api
      end

      # InfluxDb client
      #
      # @return [InfluxDB2::Client]
      def influx_client
        @influx_client ||= InfluxDB2::Client.new(
          influxdb_url,
          influxdb_token,
          bucket: influxdb_bucket,
          org: "gitlab-qa",
          precision: InfluxDB2::WritePrecision::NANOSECOND
        )
      end

      # Slack notifier
      #
      # @return [Slack::Notifier]
      def notifier
        @notifier ||= Slack::Notifier.new(
          slack_webhook_url,
          channel: slack_channel,
          username: "Reliable Spec Report"
        )
      end

      # Gitlab access token
      #
      # @return [String]
      def gitlab_access_token
        @gitlab_access_token ||= ENV["GITLAB_ACCESS_TOKEN"] || raise("Missing GITLAB_ACCESS_TOKEN env variable")
      end

      # Gitlab api url
      #
      # @return [String]
      def gitlab_api_url
        @gitlab_api_url ||= ENV["CI_API_V4_URL"] || raise("Missing CI_API_V4_URL env variable")
      end

      # Slack webhook url
      #
      # @return [String]
      def slack_webhook_url
        @slack_webhook_url ||= ENV["SLACK_WEBHOOK"] || raise("Missing SLACK_WEBHOOK env variable")
      end
    end
  end
end
