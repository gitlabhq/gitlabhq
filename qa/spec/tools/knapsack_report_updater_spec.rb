# frozen_string_literal: true

RSpec.describe QA::Tools::KnapsackReportUpdater, :aggregate_failures do
  include QA::Support::Helpers::StubEnv

  subject(:report_updater) { described_class.new(wait_before_approve: 0, wait_before_merge: 0) }

  let(:approver_id) { 1 }
  let(:mr_iid) { 1 }
  let(:approver_token) { nil }
  let(:merged_runtimes) { { "spec_file[1:1]": 0.0 } }
  let(:merged_report) { { spec_file: 0.0 } }
  let(:branch) { "qa-knapsack-master-report-update" }

  let(:http_response) { mock_response(200, { id: approver_id, iid: mr_iid }) }
  let(:logger) { instance_double(Logger, info: nil, warn: nil, error: nil) }
  let(:knapsack_reporter) do
    instance_double(
      QA::Support::KnapsackReport,
      create_knapsack_report: merged_report,
      create_merged_runtime_report: merged_runtimes
    )
  end

  # Instance double for rest client response
  #
  # @param code [Integer]
  # @param body [Hash]
  # @return [InstanceDouble]
  def mock_response(code, body)
    instance_double(RestClient::Response, code: code, body: body.to_json)
  end

  # Request args passed to rest client
  #
  # @param verb [Symbol]
  # @param path [String]
  # @param payload [Hash]
  # @param token [String]
  # @return [Hash]
  def request_args(verb, path, payload, token = "token")
    {
      method: verb,
      url: "https://gitlab.com/api/v4/projects/278964/#{path}",
      payload: payload,
      verify_ssl: false,
      headers: { "PRIVATE-TOKEN" => token }
    }.compact
  end

  # Expect merge request was created
  #
  # @param reviewer_ids [Array, nil]
  # @return [void]
  def expect_mr_created(reviewer_ids: nil)
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
      title: "Update knapsack runtime data for E2E tests",
      remove_source_branch: true,
      squash: true,
      reviewer_ids: reviewer_ids,
      labels: "group::development analytics,type::maintenance,maintenance::pipelines",
      description: "Update fallback knapsack report and example runtime data report.".then do |description|
        next description unless reviewer_ids.nil?

        "#{description}\n\ncc: @gl-dx/qe-maintainers"
      end
    }.compact))
  end

  before do
    allow(RestClient::Request).to receive(:execute).and_return(http_response)
    allow(Gitlab::QA::TestLogger).to receive(:logger).and_return(logger)
    allow(QA::Support::KnapsackReport).to receive(:new).and_return(knapsack_reporter)
    allow(QA::Runtime::Env).to receive(:canary_cookie).and_return({})

    stub_env("CI_API_V4_URL", "https://gitlab.com/api/v4")
    stub_env("GITLAB_ACCESS_TOKEN", "token")
    stub_env("QA_KNAPSACK_REPORT_APPROVER_TOKEN", approver_token)
  end

  context "without approver token" do
    it "does not attempt auto merge" do
      report_updater.update_master_report

      expect_mr_created
      expect(RestClient::Request).not_to have_received(:execute).with(hash_including(
        method: :post,
        url: "merge_requests/#{mr_iid}/approve"
      ))
      expect(RestClient::Request).not_to have_received(:execute).with(hash_including(
        method: :post,
        url: "merge_trains/merge_requests/#{mr_iid}"
      ))
    end
  end

  context "without existing branch" do
    it "creates master report merge request" do
      report_updater.update_master_report

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
          mock_response(403, { message: "Branch already exists" }),
          mock_response(200, { name: branch })
        )
    end

    it "recreates branch and creates master report merge request", :aggregate_failures do
      report_updater.update_master_report

      expect(RestClient::Request).to have_received(:execute).with(
        request_args(:post, "repository/branches", { branch: branch, ref: "master" })
      ).twice
      expect(RestClient::Request).to have_received(:execute).with(
        request_args(:delete, "repository/branches/#{branch}", nil)
      )
      expect_mr_created
    end
  end

  context "with approver token" do
    let(:approver_token) { "approver_token" }

    context "with approver id returned" do
      it "creates merge request and adds it to merge train" do
        report_updater.update_master_report

        expect_mr_created(reviewer_ids: [approver_id])
        expect(RestClient::Request).to have_received(:execute).with(
          request_args(:post, "merge_requests/#{mr_iid}/approve", {}, approver_token)
        )
        expect(RestClient::Request).to have_received(:execute).with(
          request_args(:post, "merge_trains/merge_requests/#{mr_iid}", { when_pipeline_succeeds: true }, approver_token)
        )
      end
    end

    context "without approver id returned" do
      before do
        allow(RestClient::Request).to receive(:execute).with({
          method: :get,
          url: "https://gitlab.com/api/v4/user",
          verify_ssl: false,
          headers: { "PRIVATE-TOKEN" => approver_token }
        }).and_return(mock_response(401, { message: "401 Unauthorized" }))
      end

      it "does not attempt auto merge" do
        report_updater.update_master_report

        expect_mr_created(reviewer_ids: nil)
        expect(RestClient::Request).not_to have_received(:execute).with(hash_including(
          method: :post,
          url: "merge_requests/#{mr_iid}/approve"
        ))
        expect(RestClient::Request).not_to have_received(:execute).with(hash_including(
          method: :post,
          url: "merge_trains/merge_requests/#{mr_iid}"
        ))
      end
    end
  end
end
