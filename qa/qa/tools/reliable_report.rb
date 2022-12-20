# frozen_string_literal: true

require "influxdb-client"
require "terminal-table"
require "slack-notifier"
require "colorize"

module QA
  module Tools
    class ReliableReport
      include Support::InfluxdbTools
      include Support::API

      RELIABLE_REPORT_LABEL = "reliable test report"

      # Project for report creation: https://gitlab.com/gitlab-org/gitlab
      PROJECT_ID = 278964

      def initialize(range)
        @range = range.to_i
        @slack_channel = "#quality-reports"
      end

      # Run reliable reporter
      #
      # @param [Integer] range amount of days for results range
      # @param [String] report_in_issue_and_slack
      # @return [void]
      def self.run(range: 14, report_in_issue_and_slack: "false")
        reporter = new(range)

        reporter.print_report

        if report_in_issue_and_slack == "true"
          reporter.report_in_issue_and_slack
          reporter.close_previous_reports
        end
      rescue StandardError => e
        reporter&.notify_failure(e)
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
        issue = api_update(
          :post,
          "projects/#{PROJECT_ID}/issues",
          title: "Reliable e2e test report",
          description: report_issue_body,
          labels: "#{RELIABLE_REPORT_LABEL},Quality,test,type::maintenance,automation:ml"
        )
        @report_iid = issue[:iid]
        web_url = issue[:web_url]
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

      # Close previous reliable test reports
      #
      # @return [void]
      def close_previous_reports
        puts "Closing previous reports".colorize(:green)
        issues = api_get("projects/#{PROJECT_ID}/issues?labels=#{RELIABLE_REPORT_LABEL}&state=opened")

        issues
          .reject { |issue| issue[:iid] == report_iid }
          .each do |issue|
            issue_iid = issue[:iid]
            issue_endpoint = "projects/#{PROJECT_ID}/issues/#{issue_iid}"

            puts "Closing previous report '#{issue[:web_url]}'"
            api_update(:put, issue_endpoint, state_event: "close")
            api_update(:post, "#{issue_endpoint}/notes", body: "Closed issue in favor of ##{report_iid}")
          end
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

      attr_reader :range, :slack_channel, :report_iid

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

      # Markdown formatted report issue body
      #
      # @return [String]
      def report_issue_body
        execution_interval = "(#{Date.today - range} - #{Date.today})"

        issue = []
        issue << "[[_TOC_]]"
        issue << "# Candidates for promotion to reliable #{execution_interval}"
        issue << "Total amount: **#{stable_test_runs.sum { |_k, v| v.count }}**"
        issue << stable_summary_table(markdown: true).to_s
        issue << results_markdown(:stable)
        return issue.join("\n\n") if unstable_reliable_test_runs.empty?

        issue << "# Reliable specs with failures #{execution_interval}"
        issue << "Total amount: **#{unstable_reliable_test_runs.sum { |_k, v| v.count }}**"
        issue << unstable_summary_table(markdown: true).to_s
        issue << results_markdown(:unstable)
        issue.join("\n\n")
      end

      # Stable spec summary table
      #
      # @param [Boolean] markdown
      # @return [Terminal::Table]
      def stable_summary_table(markdown: false)
        terminal_table(
          rows: stable_test_runs.map { |stage, specs| [stage, specs.length] },
          title: "Stable spec summary for past #{range} days".ljust(50),
          headings: %w[STAGE COUNT],
          markdown: markdown
        )
      end

      # Unstable reliable summary table
      #
      # @param [Boolean] markdown
      # @return [Terminal::Table]
      def unstable_summary_table(markdown: false)
        terminal_table(
          rows: unstable_reliable_test_runs.map { |stage, specs| [stage, specs.length] },
          title: "Unstable spec summary for past #{range} days".ljust(50),
          headings: %w[STAGE COUNT],
          markdown: markdown
        )
      end

      # Result tables for stable specs
      #
      # @param [Boolean] markdown
      # @return [Hash]
      def stable_results_tables(markdown: false)
        results_tables(:stable, markdown: markdown)
      end

      # Result table for unstable specs
      #
      # @param [Boolean] markdown
      # @return [Hash]
      def unstable_reliable_results_tables(markdown: false)
        results_tables(:unstable, markdown: markdown)
      end

      # Markdown formatted tables
      #
      # @param [Symbol] type result type - :stable, :unstable
      # @return [String]
      def results_markdown(type)
        runs = type == :stable ? stable_test_runs : unstable_reliable_test_runs
        results_tables(type, markdown: true).map do |stage, table|
          <<~STAGE.strip
            ## #{stage} (#{runs[stage].count})

            <details>
            <summary>Executions table</summary>

            #{table}

            </details>
          STAGE
        end.join("\n\n")
      end

      # Results table
      #
      # @param [Symbol] type result type - :stable, :unstable
      # @param [Boolean] markdown
      # @return [Hash<Symbol, Terminal::Table>]
      def results_tables(type, markdown: false)
        (type == :stable ? stable_test_runs : unstable_reliable_test_runs).to_h do |stage, specs|
          headings = ["name", "runs", "failures", "failure rate"]

          [stage, terminal_table(
            title: "Top #{type} specs in '#{stage}' stage for past #{range} days",
            headings: headings.map(&:upcase),
            markdown: markdown,
            rows: specs.map do |k, v|
              [name_column(name: k, file: v[:file], markdown: markdown), *table_params(v.values)]
            end
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
      # @param [Array] rows
      # @param [Array] headings
      # @param [String] title
      # @param [Boolean] markdown
      # @return [Terminal::Table]
      def terminal_table(rows:, headings:, title:, markdown:)
        Terminal::Table.new(
          headings: headings,
          title: markdown ? nil : title,
          rows: rows,
          style: markdown ? { border: :markdown } : { all_separators: true }
        )
      end

      # Spec parameters for table row
      #
      # @param [Array] parameters
      # @return [Array]
      def table_params(parameters)
        [*parameters[1..2], "#{parameters.last}%"]
      end

      # Name column content
      #
      # @param [String] name
      # @param [String] file
      # @param [Boolean] markdown
      # @return [String]
      def name_column(name:, file:, markdown: false)
        return "**name**: #{name}<br>**file**: #{file}" if markdown

        wrapped_name = name.length > 150 ? "#{name} ".scan(/.{1,150} /).map(&:strip).join("\n") : name
        "name: '#{wrapped_name}'\nfile: #{file.ljust(160)}"
      end

      # Test executions grouped by name
      #
      # @param [Boolean] reliable
      # @return [Hash<String, Hash>]
      def test_runs(reliable:)
        puts("Fetching data on #{reliable ? 'reliable ' : ''}test execution for past #{range} days\n".colorize(:green))

        all_runs = query_api.query(query: query(reliable))
        all_runs.each_with_object(Hash.new { |hsh, key| hsh[key] = {} }) do |table, result|
          records = table.records.sort_by { |record| record.values["_time"] }
          # skip specs that executed less time than defined by range or stopped executing before report date
          # offset 1 day due to how schedulers are configured and first run can be 1 day later
          next if (Date.today - Date.parse(records.first.values["_time"])).to_i < (range - 1)
          next if (Date.today - Date.parse(records.last.values["_time"])).to_i > 1

          last_record = records.last.values
          name = last_record["name"]
          file = last_record["file_path"].split("/").last
          stage = last_record["stage"] || "unknown"

          runs = records.count
          failed = records.count { |r| r.values["status"] == "failed" }
          failure_rate = (failed.to_f / runs) * 100

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
          from(bucket: "#{Support::InfluxdbTools::INFLUX_MAIN_TEST_METRICS_BUCKET}")
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
              r.smoke == "false" and
              r.reliable == "#{reliable}" and
              r._field == "id"
            )
            |> group(columns: ["name"])
        QUERY
      end

      # Api get request
      #
      # @param [String] path
      # @param [Hash] payload
      # @return [Hash, Array]
      def api_get(path)
        response = get("#{gitlab_api_url}/#{path}", { headers: { "PRIVATE-TOKEN" => gitlab_access_token } })
        parse_body(response)
      end

      # Api update request
      #
      # @param [Symbol] verb :post or :put
      # @param [String] path
      # @param [Hash] payload
      # @return [Hash, Array]
      def api_update(verb, path, **payload)
        response = send(
          verb,
          "#{gitlab_api_url}/#{path}",
          payload,
          { headers: { "PRIVATE-TOKEN" => gitlab_access_token } }
        )
        parse_body(response)
      end
    end
  end
end
