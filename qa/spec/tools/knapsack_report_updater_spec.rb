# frozen_string_literal: true

RSpec.describe QA::Tools::KnapsackReportUpdater do
  include QA::Support::Helpers::StubEnv

  let(:http_response) { instance_double("HTTPResponse", code: 200, body: {}.to_json) }
  let(:logger) { instance_double("Logger", info: nil, warn: nil) }
  let(:merged_runtimes) { { "spec_file[1:1]": 0.0 } }
  let(:merged_report) { { spec_file: 0.0 } }
  let(:branch) { "qa-knapsack-master-report-update" }

  let(:knapsack_reporter) do
    instance_double(
      QA::Support::KnapsackReport,
      create_knapsack_report: merged_report,
      create_merged_runtime_report: merged_runtimes
    )
  end

  def request_args(verb, path, payload)
    {
      method: verb,
      url: "https://gitlab.com/api/v4/projects/278964/#{path}",
      payload: payload,
      verify_ssl: false,
      headers: { "PRIVATE-TOKEN" => "token" }
    }.compact
  end

  before do
    allow(RestClient::Request).to receive(:execute).and_return(http_response)
    allow(Gitlab::QA::TestLogger).to receive(:logger).and_return(logger)
    allow(QA::Support::KnapsackReport).to receive(:new).with(logger).and_return(knapsack_reporter)

    stub_env("CI_API_V4_URL", "https://gitlab.com/api/v4")
    stub_env("GITLAB_ACCESS_TOKEN", "token")
  end

  def expect_mr_created
    expect(knapsack_reporter).to have_received(:create_knapsack_report).with(merged_runtimes)
    expect(RestClient::Request).to have_received(:execute).with(request_args(:post, "repository/commits", {
      branch: branch,
      commit_message: "Update master_report.json for E2E tests",
      actions: [
        {
          action: "update",
          file_path: "qa/knapsack/example_runtimes/master_report.json",
          content: "#{JSON.pretty_generate(merged_runtimes)}\n"
        },
        {
          action: "update",
          file_path: "qa/knapsack/master_report.json",
          content: "#{JSON.pretty_generate(merged_report)}\n"
        }
      ]
    }))
    expect(RestClient::Request).to have_received(:execute).with(request_args(:post, "merge_requests", {
      source_branch: branch,
      target_branch: "master",
      title: "Update master_report.json for E2E tests",
      remove_source_branch: true,
      squash: true,
      labels: "Quality,team::Test and Tools Infrastructure,type::maintenance,maintenance::pipelines",
      description: <<~DESCRIPTION
        Update fallback knapsack report with latest spec runtime data.

        @gl-dx/qe-maintainers please review and merge.
      DESCRIPTION
    }))
  end

  context "without existing branch" do
    it "creates master report merge request", :aggregate_failures do
      described_class.run

      expect(RestClient::Request).to have_received(:execute).with(request_args(:post, "repository/branches", {
        branch: branch,
        ref: "master"
      })).once
      expect_mr_created
    end
  end

  context "with existing branch" do
    before do
      allow(RestClient::Request).to receive(:execute)
        .with(request_args(:post, "repository/branches", { branch: branch, ref: "master" }))
        .and_return(
          instance_double("HTTPResponse", code: 403, body: { message: "Branch already exists" }.to_json),
          http_response
        )
    end

    it "recreates branch and creates master report merge request", :aggregate_failures do
      described_class.run

      expect(RestClient::Request).to have_received(:execute).with(
        request_args(:post, "repository/branches", { branch: branch, ref: "master" })
      ).twice
      expect(RestClient::Request).to have_received(:execute).with(
        request_args(:delete, "repository/branches/#{branch}", nil)
      )
      expect_mr_created
    end
  end
end
