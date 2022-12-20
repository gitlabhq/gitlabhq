# frozen_string_literal: true

describe QA::Tools::ReliableReport do
  include QA::Support::Helpers::StubEnv

  subject(:run) { described_class.run(range: range, report_in_issue_and_slack: create_issue) }

  let(:slack_notifier) { instance_double("Slack::Notifier", post: nil) }
  let(:influx_client) { instance_double("InfluxDB2::Client", create_query_api: query_api) }
  let(:query_api) { instance_double("InfluxDB2::QueryApi") }

  let(:slack_channel) { "#quality-reports" }
  let(:range) { 14 }
  let(:issue_url) { "https://gitlab.com/issue/1" }
  let(:time) { "2021-12-07T04:05:25.000000000+00:00" }

  let(:runs) do
    values = {
      "name" => "stable spec",
      "status" => "passed",
      "file_path" => "some/spec.rb",
      "stage" => "manage",
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
      )
    ]
  end

  let(:reliable_runs) do
    values = {
      "name" => "unstable spec",
      "status" => "failed",
      "file_path" => "some/spec.rb",
      "stage" => "create",
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

  def markdown_section(summary, result, stage, type)
    <<~SECTION.strip
      #{summary_table(summary, type, true)}

      ## #{stage} (1)

      <details>
      <summary>Executions table</summary>

      #{table(result, ['NAME', 'RUNS', 'FAILURES', 'FAILURE RATE'], "Top #{type} specs in '#{stage}' stage for past #{range} days", true)}

      </details>
    SECTION
  end

  def summary_table(summary, type, markdown = false)
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

  def name_column(spec_name)
    "**name**: #{spec_name}<br>**file**: spec.rb"
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

    let(:issue_body) do
      <<~TXT.strip
        [[_TOC_]]

        # Candidates for promotion to reliable (#{Date.today - range} - #{Date.today})

        Total amount: **1**

        #{markdown_section([['manage', 1]], [[name_column('stable spec'), 3, 0, '0%']], 'manage', 'stable')}

        # Reliable specs with failures (#{Date.today - range} - #{Date.today})

        Total amount: **1**

        #{markdown_section([['create', 1]], [[name_column('unstable spec'), 3, 2, '66.67%']], 'create', 'unstable')}
      TXT
    end

    before do
      allow(RestClient::Request).to receive(:execute).exactly(4).times.and_return(
        create_issue_response,
        open_issues_response,
        success_response,
        success_response
      )
    end

    it "creates report issue" do
      expect { run }.to output.to_stdout

      expect(RestClient::Request).to have_received(:execute).with(
        method: :post,
        url: issue_endpoint,
        payload: {
          title: "Reliable e2e test report",
          description: issue_body,
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
        text: <<~TEXT
          ```#{summary_table([['manage', 1]], 'stable')}```
          ```#{summary_table([['create', 1]], 'unstable')}```

          #{issue_url}
        TEXT
      )
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
