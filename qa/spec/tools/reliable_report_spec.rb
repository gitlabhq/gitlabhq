# frozen_string_literal: true

describe QA::Tools::ReliableReport do
  include QA::Support::Helpers::StubEnv

  subject(:reporter) { described_class.new(run_type, range) }

  let(:slack_notifier) { instance_double("Slack::Notifier", post: nil) }
  let(:influx_client) { instance_double("InfluxDB2::Client", create_query_api: query_api) }
  let(:query_api) { instance_double("InfluxDB2::QueryApi") }

  let(:slack_channel) { "#quality-reports" }
  let(:run_type) { "package-and-qa" }
  let(:range) { 30 }
  let(:results) { 10 }

  let(:runs) { { 0 => stable_spec, 1 => unstable_spec } }

  let(:stable_spec) do
    spec_values = { "name" => "stable spec", "status" => "passed", "file_path" => "some/spec.rb" }
    instance_double(
      "InfluxDB2::FluxTable",
      records: [
        instance_double("InfluxDB2::FluxRecord", values: spec_values),
        instance_double("InfluxDB2::FluxRecord", values: spec_values),
        instance_double("InfluxDB2::FluxRecord", values: spec_values)
      ]
    )
  end

  let(:unstable_spec) do
    spec_values = { "name" => "unstable spec", "status" => "failed", "file_path" => "some/spec.rb" }
    instance_double(
      "InfluxDB2::FluxTable",
      records: [
        instance_double("InfluxDB2::FluxRecord", values: { **spec_values, "status" => "passed" }),
        instance_double("InfluxDB2::FluxRecord", values: spec_values),
        instance_double("InfluxDB2::FluxRecord", values: spec_values)
      ]
    )
  end

  def flux_query(reliable)
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

  def table(rows, title = nil)
    Terminal::Table.new(
      headings: ["name", "runs", "failed", "failure rate"],
      style: { all_separators: true },
      title: title,
      rows: rows
    )
  end

  def name_column(spec_name)
    name = "name: '#{spec_name}'"
    file = "file: 'spec.rb'".ljust(110)

    "#{name}\n#{file}"
  end

  before do
    stub_env("QA_INFLUXDB_URL", "url")
    stub_env("QA_INFLUXDB_TOKEN", "token")
    stub_env("CI_SLACK_WEBHOOK_URL", "slack_url")

    allow(Slack::Notifier).to receive(:new).and_return(slack_notifier)
    allow(InfluxDB2::Client).to receive(:new).and_return(influx_client)
    allow(query_api).to receive(:query).with(query: query).and_return(runs)
  end

  context "with stable spec report" do
    let(:query) { flux_query(false) }
    let(:fetch_message) { "Fetching data on test execution for past #{range} days in '#{run_type}' runs" }
    let(:slack_send_message) { "Sending top stable spec report to #{slack_channel} slack channel" }
    let(:title) { "Top #{results} stable specs for past #{range} days in '#{run_type}' runs" }
    let(:rows) do
      [
        [name_column("stable spec"), 3, 0, "0%"],
        [name_column("unstable spec"), 3, 2, "66.67%"]
      ]
    end

    it "prints top stable spec report to console" do
      expect { reporter.show_top_stable }.to output("#{fetch_message}\n\n#{table(rows, title)}\n").to_stdout
    end

    it "sends top stable spec report to slack" do
      slack_args = { icon_emoji: ":mtg_green:", username: "Stable Spec Report" }

      expect { reporter.notify_top_stable }.to output("#{fetch_message}\n\n\n#{slack_send_message}\n").to_stdout
      expect(slack_notifier).to have_received(:post).with(text: "*#{title}*", **slack_args)
      expect(slack_notifier).to have_received(:post).with(text: "```#{table(rows)}```", **slack_args)
    end
  end

  context "with unstable spec report" do
    let(:query) { flux_query(true) }
    let(:fetch_message) { "Fetching data on reliable test execution for past #{range} days in '#{run_type}' runs" }
    let(:slack_send_message) { "Sending top unstable reliable spec report to #{slack_channel} slack channel" }
    let(:title) { "Top #{results} unstable reliable specs for past #{range} days in '#{run_type}' runs" }
    let(:rows) { [[name_column("unstable spec"), 3, 2, "66.67%"]] }

    it "prints top unstable spec report to console" do
      expect { reporter.show_top_unstable }.to output("#{fetch_message}\n\n#{table(rows, title)}\n").to_stdout
    end

    it "sends top unstable reliable spec report to slack" do
      slack_args = { icon_emoji: ":sadpanda:", username: "Unstable Spec Report" }

      expect { reporter.notify_top_unstable }.to output("#{fetch_message}\n\n\n#{slack_send_message}\n").to_stdout
      expect(slack_notifier).to have_received(:post).with(text: "*#{title}*", **slack_args)
      expect(slack_notifier).to have_received(:post).with(text: "```#{table(rows)}```", **slack_args)
    end
  end

  context "without unstable reliable specs" do
    let(:query) { flux_query(true) }
    let(:runs) { { 0 => stable_spec } }
    let(:fetch_message) { "Fetching data on reliable test execution for past #{range} days in '#{run_type}' runs" }
    let(:no_result_message) { "No unstable tests present!" }

    it "prints no result message to console" do
      expect { reporter.show_top_unstable }.to output("#{fetch_message}\n\n#{no_result_message}\n").to_stdout
    end

    it "skips slack notification" do
      expect { reporter.notify_top_unstable }.to output("#{fetch_message}\n\n#{no_result_message}\n").to_stdout
      expect(slack_notifier).not_to have_received(:post)
    end
  end
end
