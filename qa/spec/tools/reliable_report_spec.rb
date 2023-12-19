# frozen_string_literal: true

describe QA::Tools::ReliableReport do
  include QA::Support::Helpers::StubEnv

  describe '.run' do
    subject(:run) { described_class.run(range: range, report_in_issue_and_slack: create_issue) }

    let(:slack_notifier) { instance_double("Slack::Notifier", post: nil) }
    let(:influx_client) { instance_double("InfluxDB2::Client", create_query_api: query_api) }
    let(:query_api) { instance_double("InfluxDB2::QueryApi") }

    let(:slack_channel) { "#quality-reports" }
    let(:range) { 14 }
    let(:issue_url) { "https://gitlab.com/issue/1" }
    let(:time) { "2021-12-07T04:05:25.000000000+00:00" }
    let(:failure_message) { 'random failure message' }

    let(:runs) do
      values = {
        "name" => "stable spec1",
        "status" => "passed",
        "file_path" => "some/spec.rb",
        "stage" => "create",
        "product_group" => "code_review",
        "_time" => time
      }
      more_values = {
        "name" => "stable spec2",
        "status" => "passed",
        "file_path" => "some/spec.rb",
        "stage" => "manage",
        "product_group" => "import_and_integrate",
        "_time" => time
      }
      [
        instance_double(
          "InfluxDB2::FluxTable",
          records: [
            instance_double("InfluxDB2::FluxRecord", values: values),
            instance_double("InfluxDB2::FluxRecord", values: values),
            instance_double("InfluxDB2::FluxRecord", values: values.merge({ "_time" => Time.now.to_s }))
          ]
        ),
        instance_double(
          "InfluxDB2::FluxTable",
          records: [
            instance_double("InfluxDB2::FluxRecord", values: more_values),
            instance_double("InfluxDB2::FluxRecord", values: more_values),
            instance_double("InfluxDB2::FluxRecord", values: more_values.merge({ "_time" => Time.now.to_s }))
          ]
        )
      ]
    end

    let(:reliable_runs) do
      values = {
        "name" => "unstable spec",
        "status" => "failed",
        "file_path" => "some/spec.rb",
        "stage" => "create",
        "product_group" => "code_review",
        "failure_exception" => failure_message,
        "job_url" => "https://job/url",
        "_time" => time
      }
      more_values = {
        "name" => "unstable spec",
        "status" => "failed",
        "file_path" => "some/spec.rb",
        "stage" => "manage",
        "product_group" => "import_and_integrate",
        "failure_exception" => failure_message,
        "job_url" => "https://job/url",
        "_time" => time
      }
      [
        instance_double(
          "InfluxDB2::FluxTable",
          records: [
            instance_double("InfluxDB2::FluxRecord", values: { **values, "status" => "passed" }),
            instance_double("InfluxDB2::FluxRecord", values: values),
            instance_double("InfluxDB2::FluxRecord", values: values.merge({ "_time" => Time.now.to_s }))
          ]
        ),
        instance_double(
          "InfluxDB2::FluxTable",
          records: [
            instance_double("InfluxDB2::FluxRecord", values: { **more_values, "status" => "passed" }),
            instance_double("InfluxDB2::FluxRecord", values: more_values),
            instance_double("InfluxDB2::FluxRecord", values: more_values.merge({ "_time" => Time.now.to_s }))
          ]
        )
      ]
    end

    def flux_query(reliable:)
      <<~QUERY
        from(bucket: "e2e-test-stats-main")
          |> range(start: -#{range}d)
          |> filter(fn: (r) => r._measurement == "test-stats")
          |> filter(fn: (r) => r.run_type == "staging-full" or
            r.run_type == "staging-sanity" or
            r.run_type == "production-full" or
            r.run_type == "production-sanity" or
            r.run_type == "package-and-qa" or
            r.run_type == "nightly"
          )
          |> filter(fn: (r) => r.job_name != "airgapped" and
            r.job_name != "instance-image-slow-network" and
            r.job_name != "nplus1-instance-image"
          )
          |> filter(fn: (r) => r.status != "pending" and
            r.merge_request == "false" and
            r.quarantined == "false" and
            r.smoke == "false" and
            r.reliable == "#{reliable}"
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

    def expected_stage_markdown(result, stage, product_group, type)
      <<~SECTION.strip
        ## #{stage.capitalize} (1)

        <details>
        <summary>Executions table ~\"group::#{product_group}\" (1)</summary>

        #{table(result, ['NAME', 'RUNS', 'FAILURES', 'FAILURE RATE'], "Top #{type} specs in '#{stage}' stage for past #{range} days", true)}

        </details>
      SECTION
    end

    def expected_summary_table(summary, type, markdown = false)
      table(summary, %w[STAGE COUNT], "#{type.capitalize} spec summary for past #{range} days".ljust(50), markdown)
    end

    def table(rows, headings, title, markdown = false)
      Terminal::Table.new(
        headings: headings,
        title: markdown ? nil : title,
        rows: rows,
        style: markdown ? { border: :markdown } : { all_separators: true }
      )
    end

    def name_column(spec_name, exceptions_and_related_urls = {})
      "**Name**: #{spec_name}<br>**File**: [spec.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/qa/specs/features/some/spec.rb)#{exceptions_markdown(exceptions_and_related_urls)}"
    end

    def exceptions_markdown(exceptions_and_related_urls)
      exceptions_and_related_urls.empty? ? '' : "<br>**Exceptions**:<br>- [`#{failure_message}`](https://job/url)"
    end

    before do
      stub_env("QA_INFLUXDB_URL", "url")
      stub_env("QA_INFLUXDB_TOKEN", "token")
      stub_env("SLACK_WEBHOOK", "slack_url")
      stub_env("CI_API_V4_URL", "gitlab_api_url")
      stub_env("GITLAB_ACCESS_TOKEN", "gitlab_token")

      allow(RestClient::Request).to receive(:execute)
      allow(Slack::Notifier).to receive(:new).and_return(slack_notifier)
      allow(InfluxDB2::Client).to receive(:new).and_return(influx_client)

      allow(query_api).to receive(:query).with(query: flux_query(reliable: false)).and_return(runs)
      allow(query_api).to receive(:query).with(query: flux_query(reliable: true)).and_return(reliable_runs)
    end

    context "without report creation" do
      let(:create_issue) { "false" }

      it "does not create report issue", :aggregate_failures do
        expect { run }.to output.to_stdout

        expect(RestClient::Request).not_to have_received(:execute)
        expect(slack_notifier).not_to have_received(:post)
      end
    end

    context "with report creation" do
      let(:create_issue) { "true" }
      let(:iid) { 2 }
      let(:old_iid) { 1 }
      let(:issue_endpoint) { "gitlab_api_url/projects/278964/issues" }

      let(:common_api_args) do
        {
          verify_ssl: false,
          headers: { "PRIVATE-TOKEN" => "gitlab_token" },
          cookies: {}
        }
      end

      let(:create_issue_response) do
        instance_double(
          "RestClient::Response",
          code: 200,
          body: { web_url: issue_url, iid: iid }.to_json
        )
      end

      let(:open_issues_response) do
        instance_double(
          "RestClient::Response",
          code: 200,
          body: [{ web_url: issue_url, iid: iid }, { web_url: issue_url, iid: old_iid }].to_json
        )
      end

      let(:success_response) do
        instance_double("RestClient::Response", code: 200, body: {}.to_json)
      end

      before do
        allow(RestClient::Request).to receive(:execute).exactly(4).times.and_return(
          create_issue_response,
          open_issues_response,
          success_response,
          success_response
        )
      end

      shared_examples 'report creation' do
        it "creates report issue" do
          expect { run }.to output.to_stdout

          expect(RestClient::Request).to have_received(:execute).with(
            method: :post,
            url: issue_endpoint,
            payload: {
              title: "Reliable e2e test report",
              description: expected_issue_body,
              labels: "reliable test report,Quality,test,type::maintenance,automation:ml"
            },
            **common_api_args
          )
          expect(RestClient::Request).to have_received(:execute).with(
            method: :get,
            url: "#{issue_endpoint}?labels=reliable test report&state=opened",
            **common_api_args
          )
          expect(RestClient::Request).to have_received(:execute).with(
            method: :put,
            url: "#{issue_endpoint}/#{old_iid}",
            payload: {
              state_event: "close"
            },
            **common_api_args
          )
          expect(RestClient::Request).to have_received(:execute).with(
            method: :post,
            url: "#{issue_endpoint}/#{old_iid}/notes",
            payload: {
              body: "Closed issue in favor of ##{iid}"
            },
            **common_api_args
          )
          expect(slack_notifier).to have_received(:post).with(
            icon_emoji: ":tanuki-protect:",
            text: expected_slack_text
          )
        end
      end

      context "with disallowed exception" do
        let(:failure_message) { 'random failure message' }

        let(:expected_issue_body) do
          <<~TXT.strip
            [[_TOC_]]

            # Candidates for promotion to reliable (#{Date.today - range} - #{Date.today})

            Total amount: **2**

            #{expected_summary_table([['create', 1], ['manage', 1]], :stable, true)}

            #{expected_stage_markdown([[name_column('stable spec1'), 3, 0, '0%']], 'create', 'code review', :stable)}

            #{expected_stage_markdown([[name_column('stable spec2'), 3, 0, '0%']], 'manage', 'import and integrate', :stable)}

            # Reliable specs with failures (#{Date.today - range} - #{Date.today})

            Total amount: **2**

            #{expected_summary_table([['create', 1], ['manage', 1]], :unstable, true)}

            #{expected_stage_markdown([[name_column('unstable spec', { failure_message => 'https://job/url' }), 3, 2, '66.67%']], 'create', 'code review', :unstable)}

            #{expected_stage_markdown([[name_column('unstable spec', { failure_message => 'https://job/url' }), 3, 2, '66.67%']], 'manage', 'import and integrate', :unstable)}
          TXT
        end

        let(:expected_slack_text) do
          <<~TEXT
            ```#{expected_summary_table([['create', 1], ['manage', 1]], :stable)}```
            ```#{expected_summary_table([['create', 1], ['manage', 1]], :unstable)}```

            #{issue_url}
          TEXT
        end

        it_behaves_like "report creation"
      end

      context "with allowed exception" do
        let(:failure_message) { 'Ambiguous match' }

        let(:expected_issue_body) do
          <<~TXT.strip
            [[_TOC_]]

            # Candidates for promotion to reliable (#{Date.today - range} - #{Date.today})

            Total amount: **2**

            #{expected_summary_table([['create', 1], ['manage', 1]], :stable, true)}

            #{expected_stage_markdown([[name_column('stable spec1'), 3, 0, '0%']], 'create', 'code review', :stable)}

            #{expected_stage_markdown([[name_column('stable spec2'), 3, 0, '0%']], 'manage', 'import and integrate', :stable)}
          TXT
        end

        let(:expected_slack_text) do
          <<~TEXT
            ```#{expected_summary_table([['create', 1], ['manage', 1]], :stable)}```
            ```#{expected_summary_table([], :unstable)}```

            #{issue_url}
          TEXT
        end

        it_behaves_like "report creation"
      end
    end

    context "with failure" do
      let(:create_issue) { "true" }

      before do
        allow(query_api).to receive(:query).and_raise("Connection error!")
      end

      it "notifies failure", :aggregate_failures do
        expect { expect { run }.to raise_error("Connection error!") }.to output.to_stdout

        expect(slack_notifier).to have_received(:post).with(
          icon_emoji: ":sadpanda:",
          text: "Reliable reporter failed to create report. Error: ```Connection error!```"
        )
      end
    end
  end

  describe "#allowed_failure?" do
    subject(:reliable_report) { described_class.new(14) }

    it "returns true for an allowed failure" do
      expect(reliable_report.send(:allowed_failure?, "Couldn't find option named abc")).to be true
    end

    it "returns false for disallowed failure" do
      expect(reliable_report.send(:allowed_failure?,
        %q([Unable to find css "[data-testid=\"user_action_dropdown\"]"]))).to be false
    end
  end

  describe "#exceptions_and_related_urls" do
    subject(:reliable_report) { described_class.new(14) }

    let(:failure_message) { "This is a failure exception" }
    let(:job_url) { "https://example.com/job/url" }
    let(:failure_issue_url) { "https://example.com/failure/issue" }

    let(:records) do
      [instance_double("InfluxDB2::FluxRecord", values: values)]
    end

    context "without failure_exception" do
      let(:values) do
        {
          "failure_exception" => nil,
          "job_url" => job_url,
          "failure_issue" => failure_issue_url
        }
      end

      it "returns an empty hash" do
        expect(reliable_report.send(:exceptions_and_related_urls, records)).to be_empty
      end

      context "with failure_exception" do
        context "without failure_issue" do
          let(:values) do
            {
              "failure_exception" => failure_message,
              "job_url" => job_url
            }
          end

          it "returns job_url as value" do
            expect(reliable_report.send(:exceptions_and_related_urls, records).values).to eq([job_url])
          end
        end

        context "with failure_issue and job_url" do
          let(:values) do
            {
              "failure_exception" => failure_message,
              "failure_issue" => failure_issue_url,
              "job_url" => job_url
            }
          end

          it "returns failure_issue as value" do
            expect(reliable_report.send(:exceptions_and_related_urls, records).values).to eq([failure_issue_url])
          end
        end
      end
    end
  end
end
