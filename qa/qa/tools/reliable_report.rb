# frozen_string_literal: true

require "influxdb-client"
require "terminal-table"
require "slack-notifier"
require 'rainbow/refinement'

module QA
  module Tools
    class ReliableReport
      using Rainbow
      include Support::InfluxdbTools
      include Support::API

      RELIABLE_REPORT_LABEL = "reliable test report"
      PROMOTION_BATCH_LIMIT = 10

      ALLOWED_EXCEPTION_PATTERNS = [
        /Couldn't find option named/,
        /Waiting for [\w:]+ to be removed/,
        /503 Server Unavailable/,
        /\w+ did not appear on [\w:]+ as expected/,
        /Internal Server Error/,
        /Ambiguous match/,
        /500 Error - GitLab/,
        /Page did not fully load/,
        /Timed out reading data from server/,
        /Internal API error/,
        /Something went wrong/
      ].freeze

      # Project for report creation: https://gitlab.com/gitlab-org/gitlab
      PROJECT_ID = 278964
      BLOB_MASTER = 'https://gitlab.com/gitlab-org/gitlab/-/blob/master'
      FEATURES_DIR = '/qa/qa/specs/features'

      # @param [Integer] range amount of days for results range
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
          reporter.write_specs_json
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
        puts "#{summary_table(stable: true)}\n\n"
        puts "Total amount: #{stable_test_runs.sum { |_k, v| v.count }}\n\n"
        print_results(stable_results_tables)
        return puts("No unstable blocking tests present!".yellow) if unstable_blocking_test_runs.empty?

        puts "#{summary_table(stable: false)}\n\n"
        puts "Total amount: #{unstable_blocking_test_runs.sum { |_k, v| v.count }}\n\n"
        print_results(unstable_blocking_results_tables)
      end

      # Create report issue
      #
      # @return [void]
      def report_in_issue_and_slack
        puts "Creating report".green
        issue = api_update(
          :post,
          "projects/#{PROJECT_ID}/issues",
          title: "Reliable e2e test report",
          description: report_issue_body,
          labels: "#{RELIABLE_REPORT_LABEL},Quality,test,type::maintenance,automation:ml"
        )
        @report_iid = issue[:iid]
        @report_web_url = issue[:web_url]
        puts "Created report issue: #{@report_web_url}"

        puts "Sending slack notification".green
        notifier.post(
          icon_emoji: ":tanuki-protect:",
          text: <<~TEXT
            ```#{summary_table(stable: true)}```
            ```#{summary_table(stable: false)}```

            #{@report_web_url}
          TEXT
        )
        puts "Done!"
      end

      # Close previous reliable test reports
      #
      # @return [void]
      def close_previous_reports
        puts "Closing previous reports".green
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

      def write_specs_json
        # 'unstable_specs.json' contain unstable specs tagged blocking
        # 'stable_specs.json' contain stable specs not tagged blocking
        File.write('tmp/unstable_specs.json', JSON.pretty_generate(specs_attributes(blocking: true)))
        File.write('tmp/stable_specs.json', JSON.pretty_generate(specs_attributes(blocking: false)))
      end

      private

      attr_reader :range, :slack_channel, :report_iid, :report_web_url

      # Slack notifier
      #
      # @return [Slack::Notifier]
      def notifier
        @notifier ||= Slack::Notifier.new(
          slack_webhook_url,
          channel: slack_channel,
          username: "Reliable Report"
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
        issue << "# Candidates for promotion to blocking #{execution_interval}"
        issue << "**Note: MRs will be auto-created for promoting the top #{PROMOTION_BATCH_LIMIT} " \
                 "specs sorted by most number of successful runs**"
        issue << "Total amount: **#{test_count(stable_test_runs)}**"
        issue << summary_table(markdown: true, stable: true).to_s
        issue << results_markdown(:stable)
        return issue.join("\n\n") if unstable_blocking_test_runs.empty?

        issue << "# Blocking specs with failures #{execution_interval}"
        issue << "**Note:**"
        issue << "* Only failures from the nightly, e2e-package-and-test and e2e-test-on-gdk pipelines are considered"
        issue << "* Only specs that have a failure rate of equal or greater than 1 percent are considered"
        issue << "* Quarantine MRs will be created for all specs listed below"
        issue << "Total amount: **#{test_count(unstable_blocking_test_runs)}**"
        issue << summary_table(markdown: true, stable: false).to_s
        issue << results_markdown(:unstable)
        issue.join("\n\n")
      end

      # Spec summary table
      #
      # @param [Boolean] markdown
      # @param [Boolean] stable
      # @return [Terminal::Table]
      def summary_table(markdown: false, stable: true)
        test_runs = stable ? stable_test_runs : unstable_blocking_test_runs
        terminal_table(
          rows: test_runs.map do |stage, stage_specs|
            [stage, stage_specs.sum { |_k, group_specs| group_specs.length }]
          end,
          title: "#{stable ? 'Stable' : 'Unstable'} spec summary for past #{range} days".ljust(50),
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
      def unstable_blocking_results_tables(markdown: false)
        results_tables(:unstable, markdown: markdown)
      end

      # Markdown formatted tables
      #
      # @param [Symbol] type result type - :stable, :unstable
      # @return [String]
      def results_markdown(type)
        runs = type == :stable ? stable_test_runs : unstable_blocking_test_runs
        results_tables(type, markdown: true).map do |stage, group_tables|
          markdown = "## #{stage.capitalize} (#{runs[stage].sum { |_k, group_runs| group_runs.count }})\n\n"

          markdown << group_tables.map { |product_group, table| group_results_markdown(product_group, table) }.join
        end.join("\n\n")
      end

      # Markdown formatted group results table
      #
      # @param [String] product_group
      # @param [Terminal::Table] table
      # @return [String]
      def group_results_markdown(product_group, table)
        <<~MARKDOWN.chomp
          <details>
          <summary>Executions table ~"group::#{product_group.tr('_', ' ')}" (#{table.rows.size})</summary>

          #{table}

          </details>
        MARKDOWN
      end

      # Results table
      #
      # @param [Symbol] type result type - :stable, :unstable
      # @param [Boolean] markdown
      # @return [Hash<String, Hash<String, Terminal::Table>>] grouped by stage and product_group
      def results_tables(type, markdown: false)
        (type == :stable ? stable_test_runs : unstable_blocking_test_runs).to_h do |stage, specs|
          headings = ['NAME', 'RUNS', 'FAILURES', 'FAILURE RATE'].freeze
          [stage, specs.transform_values do |group_specs|
            terminal_table(
              title: "Top #{type} specs in '#{stage}::#{specs.key(group_specs)}' group for past #{range} days",
              headings: headings,
              markdown: markdown,
              rows: group_specs.map do |name, result|
                [
                  name_column(name: name, file: result[:file], link: result[:link],
                    exceptions_and_related_urls: result[:exceptions_and_related_urls], markdown: markdown),
                  *table_params(result.values)
                ]
              end
            )
          end]
        end
      end

      # Stable specs
      #
      # @return [Hash]
      def stable_test_runs
        @top_stable ||= begin
          stable_specs = test_runs(blocking: false).each do |stage, stage_specs|
            stage_specs.transform_values! do |group_specs|
              group_specs.reject { |k, v| v[:failure_rate] != 0 }
                         .sort_by { |k, v| -v[:runs] }
                         .to_h
            end
          end
          stable_specs.transform_values { |v| v.reject { |_, v| v.empty? } }.reject { |_, v| v.empty? }
        end
      end

      # Unstable blocking specs
      #
      # @return [Hash]
      def unstable_blocking_test_runs
        @top_unstable_blocking ||= begin
          unstable = test_runs(blocking: true).each do |_stage, stage_specs|
            stage_specs.transform_values! do |group_specs|
              group_specs.reject { |_, v| v[:failure_rate] == 0 }
                         .sort_by { |_, v| -v[:failure_rate] }
                         .to_h
            end
          end
          unstable.transform_values { |v| v.reject { |_, v| v.empty? } }.reject { |_, v| v.empty? }
        end
      end

      def print_results(results)
        results.each do |_stage, stage_results|
          stage_results.each_value { |group_results_table| puts "#{group_results_table}\n\n" }
        end
      end

      def test_count(test_runs)
        test_runs.sum do |_stage, stage_results|
          stage_results.sum { |_product_group, group_results| group_results.count }
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
        [*parameters[2..3], "#{parameters.last}%"]
      end

      # Name column content
      #
      # @param [String] name
      # @param [String] file
      # @param [String] link
      # @param [Hash] exceptions_and_related_urls
      # @param [Boolean] markdown
      # @return [String]
      def name_column(name:, file:, link:, exceptions_and_related_urls:, markdown: false)
        if markdown
          return "**Name**: #{name}<br>**File**: " \
                 "[#{file}](#{link})#{exceptions_markdown(exceptions_and_related_urls)}"
        end

        wrapped_name = name.length > 150 ? "#{name} ".scan(/.{1,150} /).map(&:strip).join("\n") : name
        "Name: '#{wrapped_name}'\nFile: #{file.ljust(160)}"
      end

      # Formatted exceptions with link to job url
      #
      # @param [Hash] exceptions_and_related_urls
      # @return [String]
      def exceptions_markdown(exceptions_and_related_urls)
        return '' if exceptions_and_related_urls.empty?

        "<br>**Exceptions**:#{exceptions_and_related_urls.keys.map do |e|
          "<br>- [`#{e.truncate(250).tr('`', "'")}`](#{exceptions_and_related_urls[e]})"
        end.join('')}"
      end

      def api_query_notblocking
        @api_query_notblocking ||= begin
          log_fetching_query_data(true)
          query_api.query(query: query(false))
        end
      end

      def api_query_blocking
        @api_query_blocking ||= begin
          log_fetching_query_data(true)
          query_api.query(query: query(true))
        end
      end

      def log_fetching_query_data(reliable)
        puts("Fetching data on #{reliable ? 'reliable ' : ''}test execution for past #{range} days\n".green)
      end

      def specs_attributes(blocking:)
        all_runs = query_for(blocking: blocking)

        specs_array = all_runs.each_with_object([]) do |table, arr|
          records = table.records.sort_by { |record| record.values["_time"] }

          next if within_execution_range(records.first.values["_time"], records.last.values["_time"])

          result = spec_attributes_per_run(records)

          # When collecting specs not in blocking bucket for promotion, skip specs with failures
          next if !blocking && result[:failed] != 0

          next if blocking && skip_blocking_spec_record?(failed_count: result[:failed],
            failure_issue: result[:failure_issue],
            failed_run_type: result[:failed_run_type],
            failure_rate: result[:failure_rate])

          arr << result
        end

        specs_array = specs_array.sort_by { |item| item[:runs] }.reverse unless blocking

        {
          type: blocking ? 'Unstable Specs' : 'Stable Specs',
          report_issue: report_web_url,
          specs: specs_array
        }
      end

      def skip_blocking_spec_record?(failed_count:, failure_issue:, failed_run_type:, failure_rate:)
        # For unstable blocking specs, skip if no failures or
        return true if failed_count == 0 ||
          # skip if a failure issue does not exist or
          failure_issue&.exclude?('issues') ||
          # skip if run type is other than nightly and non-MR e2e-package-and-test pipeline or
          (failed_run_type & %w[e2e-package-and-test e2e-test-on-gdk nightly]).empty? ||
          # skip if failure rate of tests is less than or equal to 1 percent
          failure_rate <= 1

        false
      end

      def spec_attributes_per_run(records)
        failed_records = records.select do |r|
          r.values["status"] == "failed" && !allowed_failure?(r.values["failure_exception"])
        end

        failure_issue = issue_for_most_failures(failed_records)
        last_record = records.last.values
        name = last_record["name"]
        file = last_record["file_path"].split("/").last
        link = BLOB_MASTER + FEATURES_DIR + last_record["file_path"]
        file_path = FEATURES_DIR + last_record["file_path"]
        stage = last_record["stage"] || "unknown"
        testcase = last_record["testcase"]
        run_type = records.map { |record| record.values['run_type'] }.uniq
        failed_run_type = failed_records.map { |record| record.values['run_type'] }.uniq
        product_group = last_record["product_group"] || "unknown"
        runs = records.count
        failure_rate = (failed_records.count.to_f / runs) * 100

        {
          stage: stage,
          product_group: product_group,
          name: name,
          file: file,
          link: link,
          runs: runs,
          failed: failed_records.count,
          failure_issue: failure_issue || '',
          failure_rate: failure_rate == 0 ? failure_rate.round(0) : failure_rate.round(2),
          testcase: testcase,
          file_path: file_path,
          all_run_type: run_type,
          failed_run_type: failed_run_type
        }
      end

      def query_for(blocking:)
        blocking ? api_query_blocking : api_query_notblocking
      end

      # rubocop:disable Metrics/AbcSize
      # Test executions grouped by name
      #
      # @param [Boolean] blocking
      # @return [Hash<String, Hash>]
      def test_runs(blocking:)
        all_runs = query_for(blocking: blocking)

        all_runs.each_with_object(Hash.new { |hsh, key| hsh[key] = {} }) do |table, result|
          records = table.records.sort_by { |record| record.values["_time"] }

          next if within_execution_range(records.first.values["_time"], records.last.values["_time"])

          last_record = records.last.values

          name = last_record["name"]
          file = last_record["file_path"].split("/").last
          link = BLOB_MASTER + FEATURES_DIR + last_record["file_path"]
          stage = last_record["stage"] || "unknown"
          product_group = last_record["product_group"] || "unknown"

          runs = records.count

          failed_records = records.select do |r|
            r.values["status"] == "failed" && !allowed_failure?(r.values["failure_exception"])
          end

          failure_issue = issue_for_most_failures(failed_records)

          failed_run_type = failed_records.map { |record| record.values['run_type'] }.uniq

          failure_rate = (failed_records.count.to_f / runs) * 100

          next if blocking && skip_blocking_spec_record?(failed_count: failed_records.count,
            failure_issue: failure_issue, failed_run_type: failed_run_type, failure_rate: failure_rate)

          result[stage][product_group] ||= {}
          result[stage][product_group][name] = {
            file: file,
            link: link,
            runs: runs,
            failed: failed_records.count,
            exceptions_and_related_urls: exceptions_and_related_urls(records),
            failure_rate: failure_rate == 0 ? failure_rate.round(0) : failure_rate.round(2)
          }
        end
      end

      # rubocop:enable Metrics/AbcSize

      # Return hash of exceptions as key and failure_issue or job_url urls as value
      #
      # @param [Array<InfluxDB2::FluxRecord>] records
      # @return [Hash]
      def exceptions_and_related_urls(records)
        records_with_exception = records.reject { |r| !r.values["failure_exception"] }

        # Since exception is the key in the below hash, only one instance of an occurrence is kept
        records_with_exception.to_h do |r|
          [r.values["failure_exception"], r.values["failure_issue"] || r.values["job_url"]]
        end
      end

      # Return the failure that has the most occurrence
      #
      # @param [Array<InfluxDB2::FluxRecord>] records
      # @return [String] the failure with most occurrence
      def issue_for_most_failures(records)
        return '' if records.empty?

        issues = records.filter_map { |r| r.values["failure_issue"] }
        return '' if issues.empty?

        issues.tally.max_by { |_, count| count }&.first
      end

      # Check if failure is allowed
      #
      # @param [String] failure_exception
      # @return [Boolean]
      def allowed_failure?(failure_exception)
        ALLOWED_EXCEPTION_PATTERNS.any? { |pattern| pattern.match?(failure_exception) }
      end

      # Returns true if first_time is before our range, or if last_time is before report date
      # offset 1 day due to how schedulers are configured and first run can be 1 day later
      #
      # @param [String] first_time
      # @param [String] last_time
      # @return [Boolean]
      def within_execution_range(first_time, last_time)
        (Date.today - Date.parse(first_time)).to_i < (range - 1) || (Date.today - Date.parse(last_time)).to_i > 1
      end

      # Flux query
      #
      # @param [Boolean] blocking
      # @return [String]
      def query(blocking)
        <<~QUERY
          from(bucket: "#{Support::InfluxdbTools::INFLUX_MAIN_TEST_METRICS_BUCKET}")
            |> range(start: -#{range}d)
            |> filter(fn: (r) => r._measurement == "test-stats")
            |> filter(fn: (r) => r.run_type == "staging-full" or
              r.run_type == "staging-sanity" or
              r.run_type == "production-full" or
              r.run_type == "production-sanity" or
              r.run_type == "e2e-package-and-test" or
              r.run_type == "e2e-test-on-gdk" or
              r.run_type == "nightly"
            )
            |> filter(fn: (r) => r.job_name != "airgapped" and
              r.job_name != "nplus1-instance-image"
            )
            |> filter(fn: (r) => r.status != "pending" and
              r.merge_request == "false" and
              r.quarantined == "false" and
              r.smoke == "false" and
              r.blocking == "#{blocking}"
            )
            |> filter(fn: (r) => r["_field"] == "job_url" or
              r["_field"] == "failure_exception" or
              r["_field"] == "id" or
              r["_field"] == "failure_issue"
            )
            |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")
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
