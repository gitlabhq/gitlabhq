# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles, RSpec/VerifiedDoubleReference -- fog/google generates classes on the fly and will fail verified doubles

RSpec.describe QA::Support::KnapsackReport do
  let(:logger) { instance_double(Logger, info: nil, debug: nil) }
  let(:gcs_client) { double("Fog::Storage::GoogleJSON::Real") }

  let(:test_pattern) { "#{QA::Specs::Runner::DEFAULT_TEST_PATH}/**/*_spec.rb" }
  let(:report_enabled) { true }
  let(:json_key) { "some-test-key-json-that-is-not-file" }
  let(:bucket) { "knapsack-reports" }

  let(:env) do
    {
      "CI_JOB_NAME_SLUG" => "test-job",
      "QA_RUN_TYPE" => "test",
      "QA_KNAPSACK_REPORT_GCS_CREDENTIALS" => json_key
    }
  end

  subject(:knapsack_report) { described_class.new(logger: logger, test_pattern: test_pattern) }

  before do
    allow(QA::Runtime::Env).to receive(:knapsack?).and_return(report_enabled)
    allow(Fog::Storage::Google).to receive(:new)
      .with(google_project: "gitlab-qa-resources", google_json_key_string: json_key)
      .and_return(gcs_client)

    stub_const("ENV", env)
  end

  describe "#configure!" do
    shared_examples "knapsack configurator" do
      it "configures knapsack reporter" do
        knapsack_report.configure!

        expect(Knapsack).to have_received(:logger=).with(logger)
        expect(env["KNAPSACK_TEST_DIR"]).to eq("qa/specs/features")
        expect(env["KNAPSACK_REPORT_PATH"]).to eq("knapsack/master_report.json")
        expect(env["KNAPSACK_TEST_FILE_PATTERN"]).to eq(test_pattern)
      end
    end

    before do
      allow(Knapsack).to receive(:logger=)
    end

    context "with default arguments" do
      it_behaves_like "knapsack configurator"
    end

    context "with custom test file pattern" do
      let(:test_pattern) { "test/pattern/**/*_spec.rb" }

      it_behaves_like "knapsack configurator"
    end
  end

  describe "#create_local_report!" do
    let(:report_path) { "knapsack/test-job-knapsack-report.json" }
    let(:example_data) do
      {
        "./qa/specs/features/api/10_govern/group_access_token_spec.rb[1:1:1]" => "passed",
        "./qa/specs/features/api/10_govern/group_access_token_spec.rb[1:1:2]" => "pending",
        "./qa/specs/features/api/10_govern/project_access_token_spec.rb[1:1:1:1]" => "pending",
        "./qa/specs/features/api/10_govern/project_access_token_spec.rb[1:1:1:2]" => "pending"
      }
    end

    let(:runtime_report) do
      {
        "./qa/specs/features/api/10_govern/group_access_token_spec.rb[1:1:1]" => 19.388024117,
        "./qa/specs/features/api/10_govern/project_access_token_spec.rb[1:1:1:1]" => 23.771732228
      }
    end

    let(:final_report) do
      {
        "qa/specs/features/api/10_govern/group_access_token_spec.rb" => 19.398,
        "qa/specs/features/api/10_govern/project_access_token_spec.rb" => 0.020
      }
    end

    before do
      allow(JSON).to receive(:load_file).with("knapsack/example_runtimes/master_report.json").and_return(runtime_report)
      allow(File).to receive(:write).with(report_path, kind_of(String))
    end

    it "creates local knapsack report" do
      expect(knapsack_report.create_local_report!(example_data)).to eq(final_report)

      expect(File).to have_received(:write).with(report_path, final_report.to_json)
      expect(env["KNAPSACK_REPORT_PATH"]).to eq(report_path)
    end
  end

  describe "#upload_example_runtimes" do
    let(:glob_pattern) { "tmp/rspec-*.json" }
    let(:json_files) { [mocked_file("rspec-1.json"), mocked_file("rspec-2.json")] }

    before do
      allow(Pathname).to receive(:glob).and_return(json_files)
    end

    def mocked_file(name)
      instance_double(Pathname, to_s: "tmp/#{name}", extname: ".#{name.split('.').last}")
    end

    context "when glob does not return any files" do
      let(:json_files) { [] }

      it "raises error" do
        expect { knapsack_report.upload_example_runtimes(glob_pattern) }.to raise_error(
          "Glob '#{glob_pattern}' did not contain any valid report files!"
        )
      end
    end

    context "when glob pattern does not return any json files" do
      let(:json_files) { [mocked_file("rspec-1.txt")] }

      it "raises error" do
        expect { knapsack_report.upload_example_runtimes(glob_pattern) }.to raise_error(
          "Glob '#{glob_pattern}' did not contain any valid report files!"
        )
      end
    end

    context "when QA_RUN_TYPE is not set" do
      let(:env) { {} }

      it "raises error" do
        expect { knapsack_report.upload_example_runtimes(glob_pattern) }.to raise_error(
          "QA_RUN_TYPE must be set for custom report"
        )
      end
    end

    context "when glob pattern returns valid json report files" do
      before do
        allow(gcs_client).to receive(:put_object)
        allow(JSON).to receive(:load_file).with(json_files.first, symbolize_names: true).and_return({
          examples: [
            {
              id: "./container_registry_spec.rb[1:1]",
              run_time: 540.824672,
              status: "passed",
              ignore_runtime_data: false
            },
            {
              id: "./container_registry_spec.rb[1:2]",
              run_time: 540.824672,
              status: "passed",
              ignore_runtime_data: true
            }
          ]
        })
        allow(JSON).to receive(:load_file).with(json_files.last, symbolize_names: true).and_return({
          examples: [
            {
              id: "./container_registry_spec.rb[1:3]",
              run_time: 240.824672,
              status: "passed",
              ignore_runtime_data: false
            },
            {
              id: "./container_registry_spec.rb[1:4]",
              run_time: 540.824672,
              status: "pending"
            }
          ]
        })
      end

      it "uploads example runtimes to gcs bucket" do
        knapsack_report.upload_example_runtimes(glob_pattern)

        expect(gcs_client).to have_received(:put_object).with(
          "knapsack-reports",
          "example_runtimes/test.json",
          JSON.pretty_generate({
            "./container_registry_spec.rb[1:1]" => 540.824672,
            "./container_registry_spec.rb[1:3]" => 240.824672
          })
        )
      end
    end
  end

  describe "#create_merged_runtime_report" do
    let(:gcs_items) { instance_double("Google::Apis::StorageV1::Objects", items: runtime_reports) }

    let(:runtime_reports) do
      [
        instance_double("Google::Apis::StorageV1::Object", name: "example_runtimes/e2e-test-on-cng.json"),
        instance_double("Google::Apis::StorageV1::Object", name: "example_runtimes/e2e-test-on-gdk.json")
      ]
    end

    let(:report_jsons) do
      [
        {
          body: {
            "./qa/specs/group_access_token_spec.rb[1:1:1]": 11.458777161,
            "./qa/specs/group_access_token_spec.rb[1:1:2]": 6.763079123
          }.to_json
        },
        {
          body: {
            "./qa/specs/group_access_token_spec.rb[1:1:1]": 9.458777161,
            "./qa/specs/group_access_token_spec.rb[1:1:2]": 7.763079123
          }.to_json
        }
      ]
    end

    before do
      allow(gcs_client).to receive(:list_objects)
        .with(bucket, prefix: "example_runtimes")
        .and_return(gcs_items)
      allow(gcs_client).to receive(:get_object)
        .with(bucket, /#{runtime_reports.map(&:name).join('|')}/)
        .and_return(*report_jsons)
    end

    it "creates merged runtime report with longest runtimes" do
      expect(knapsack_report.create_merged_runtime_report).to eq({
        "./qa/specs/group_access_token_spec.rb[1:1:1]" => 11.458777161,
        "./qa/specs/group_access_token_spec.rb[1:1:2]" => 7.763079123
      })
    end
  end

  describe "#create_knapsack_report" do
    let(:runtime_report) do
      {
        "./qa/specs/group_access_token_spec.rb[1:1:1]" => 11.458777161,
        "./qa/specs/group_access_token_spec.rb[1:1:2]" => 6.763079123,
        "./qa/specs/project_access_token_spec.rb[1:1:1:1]" => 23.771732228
      }
    end

    it "creates knapsack report from spec runtimes" do
      expect(knapsack_report.create_knapsack_report(runtime_report)).to eq({
        "qa/specs/group_access_token_spec.rb" => 18.221856284,
        "qa/specs/project_access_token_spec.rb" => 23.771732228
      })
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles, RSpec/VerifiedDoubleReference
