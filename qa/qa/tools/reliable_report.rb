# frozen_string_literal: true

require "influxdb-client"
require "terminal-table"
require "slack-notifier"

module QA
  module Tools
    class ReliableReport
      def initialize(run_type, range = 30)
        @results = 10
        @slack_channel = "#quality-reports"
        @range = range
        @run_type = run_type
        @stable_title = "Top #{results} stable specs for past #{@range} days in '#{run_type}' runs"
        @unstable_title = "Top #{results} unstable reliable specs for past #{@range} days in '#{run_type}' runs"
      end

      # Print top stable specs
      #
      # @return [void]
      def show_top_stable
        puts terminal_table(
          rows: top_stable.map { |k, v| [name_column(k, v[:file]), *table_params(v.values)] },
          title: stable_title
        )
      end

      # Post top stable spec report to slack
      # Slice table in to multiple messages due to max char limitation
      #
      # @return [void]
      def notify_top_stable
        tables = top_stable.each_slice(5).map do |slice|
          terminal_table(
            rows: slice.map { |spec| [name_column(spec[0], spec[1][:file]), *table_params(spec[1].values)] }
          )
        end

        puts "\nSending top stable spec report to #{slack_channel} slack channel"
        slack_args = { icon_emoji: ":mtg_green:", username: "Stable Spec Report" }
        notifier.post(text: "*#{stable_title}*", **slack_args)
        tables.each { |table| notifier.post(text: "```#{table}```", **slack_args) }
      end

      # Print top unstable specs
      #
      # @return [void]
      def show_top_unstable
        return puts("No unstable tests present!") if top_unstable_reliable.empty?

        puts terminal_table(
          rows: top_unstable_reliable.map { |k, v| [name_column(k, v[:file]), *table_params(v.values)] },
          title: unstable_title
        )
      end

      # Post top unstable reliable spec report to slack
      # Slice table in to multiple messages due to max char limitation
      #
      # @return [void]
      def notify_top_unstable
        return puts("No unstable tests present!") if top_unstable_reliable.empty?

        tables = top_unstable_reliable.each_slice(5).map do |slice|
          terminal_table(
            rows: slice.map { |spec| [name_column(spec[0], spec[1][:file]), *table_params(spec[1].values)] }
          )
        end

        puts "\nSending top unstable reliable spec report to #{slack_channel} slack channel"
        slack_args = { icon_emoji: ":sadpanda:", username: "Unstable Spec Report" }
        notifier.post(text: "*#{unstable_title}*", **slack_args)
        tables.each { |table| notifier.post(text: "```#{table}```", **slack_args) }
      end

      private

      attr_reader :results,
                  :slack_channel,
                  :range,
                  :run_type,
                  :stable_title,
                  :unstable_title

      # Top stable specs
      #
      # @return [Hash]
      def top_stable
        @top_stable ||= runs(reliable: false).sort_by { |k, v| [v[:failure_rate], -v[:runs]] }[0..results - 1].to_h
      end

      # Top unstable reliable specs
      #
      # @return [Hash]
      def top_unstable_reliable
        @top_unstable_reliable ||= runs(reliable: true)
          .reject { |k, v| v[:failure_rate] == 0 }
          .sort_by { |k, v| -v[:failure_rate] }[0..results - 1]
          .to_h
      end

      # Terminal table for result formatting
      #
      # @return [Terminal::Table]
      def terminal_table(rows:, title: nil)
        Terminal::Table.new(
          headings: ["name", "runs", "failed", "failure rate"],
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
        spec_name = name.length > 100 ? "#{name} ".scan(/.{1,100} /).map(&:strip).join("\n") : name
        name_line = "name: '#{spec_name}'"
        file_line = "file: '#{file}'"

        "#{name_line}\n#{file_line.ljust(110)}"
      end

      # Test executions grouped by name
      #
      # @param [Boolean] reliable
      # @return [Hash]
      def runs(reliable:)
        puts("Fetching data on #{reliable ? 'reliable ' : ''}test execution for past 30 days in '#{run_type}' runs")
        puts

        query_api.query(query: query(reliable)).values.each_with_object({}) do |table, result|
          records = table.records
          name = records.last.values["name"]
          file = records.last.values["file_path"].split("/").last
          runs = records.count
          failed = records.count { |r| r.values["status"] == "failed" }
          failure_rate = (failed.to_f / runs.to_f) * 100

          result[name] = {
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
        from(bucket: "e2e-test-stats")
          |> range(start: -#{range}d)
          |> filter(fn: (r) => r._measurement == "test-stats" and
            r.run_type == "#{run_type}" and
            r.status != "pending" and
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
          bucket: "e2e-test-stats",
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
          username: "Reliable spec reporter"
        )
      end

      # InfluxDb instance url
      #
      # @return [String]
      def influxdb_url
        @influxdb_url ||= ENV["QA_INFLUXDB_URL"] || raise("Missing QA_INFLUXDB_URL environment variable")
      end

      # Influxdb token
      #
      # @return [String]
      def influxdb_token
        @influxdb_token ||= ENV["QA_INFLUXDB_TOKEN"] || raise("Missing QA_INFLUXDB_TOKEN environment variable")
      end

      # Slack webhook url
      #
      # @return [String]
      def slack_webhook_url
        @slack_webhook_url ||= ENV["CI_SLACK_WEBHOOK_URL"] || raise("Missing CI_SLACK_WEBHOOK_URL environment variable")
      end
    end
  end
end
