# frozen_string_literal: true

require 'active_support/testing/time_helpers'

RSpec.describe QA::Tools::Ci::CodePathsMapping do
  include QA::Support::Helpers::StubEnv
  include ActiveSupport::Testing::TimeHelpers

  let(:glob) { "test_code_paths/*.json" }
  let(:file_paths) { ["/test_code/test_code_path_mappings.json"] }
  let(:logger) { instance_double("Logger", info: true, warn: true, debug: true) }
  let(:gcs_client_options) { { force: true, content_type: 'application/json' } }
  let(:gcs_client) { double("Fog::Storage::GoogleJSON::Real", put_object: nil) } # rubocop:disable RSpec/VerifiedDoubles -- Class has `put_object` method but is not getting verified
  let(:gcs_project) { 'gitlab-qa-resources' }
  let(:gcs_bucket_name) { 'code-path-mappings' }
  let(:gcs_credentials) { 'code-path-mappings-gcs-credentials' }
  let(:mapping_json) { code_path_mappings_data.to_json }
  let(:code_path_mappings_data) do
    {
      "path_to_spec:rb": ['lib/model.rb']
    }
  end

  let(:commit_ref) { 'master' }
  let(:run_type) { 'e2e-test-on-gdk' }
  let(:file_path) { "#{commit_ref}/#{run_type}/test-code-paths-mapping-merged-pipeline-1.json" }

  let(:pretty_generated_mapping_json) do
    JSON.pretty_generate(code_path_mappings_data)
  end

  before do
    allow(Fog::Storage::Google).to receive(:new)
                                     .with(google_project: gcs_project,
                                       google_json_key_string: gcs_credentials)
                                     .and_return(gcs_client)
    allow(Gitlab::QA::TestLogger).to receive(:logger) { logger }
    allow(Dir).to receive(:glob).with(glob) { file_paths }
    allow(::File).to receive(:read).with(anything).and_return(code_path_mappings_data.to_json)
    stub_env('QA_CODE_PATH_MAPPINGS_GCS_CREDENTIALS', gcs_credentials)
    stub_env('QA_RUN_TYPE', run_type)
    stub_env('CI_COMMIT_REF_SLUG', commit_ref)
    stub_env('CI_PIPELINE_ID', 1)
  end

  context "with mapping files present" do
    it "exports mapping json to GCS and writes it as job artifact", :aggregate_failures do
      expect(logger).to receive(:info).with("Number of mapping files found: #{file_paths.size}")
      expect(gcs_client).to receive(:put_object).with(gcs_bucket_name, file_path, pretty_generated_mapping_json)
      described_class.export(glob)
    end
  end

  context "with no mapping files present" do
    let(:file_paths) { [] }

    it "exits without any exception raised but logs the error", :aggregate_failures do
      expect(logger).to receive(:warn).with(/No files matched pattern/).once
      expect(::File).not_to receive(:write)
      described_class.export(glob)
    end
  end

  context "with import" do
    subject(:code_paths_mapping) { described_class.new }

    let(:branch) { "master" }
    let(:run_type) { "e2e-test-on-gdk" }
    let(:file_path_2) { "#{branch}/#{run_type}/test-code-paths-mapping-merged-pipeline-2.json" }

    let(:google_api_object_1) do
      instance_double('Google::Apis::StorageV1::Object',
        name: "test_path", bucket: "code-path-mappings")
    end

    let(:google_api_object_2) do
      instance_double('Google::Apis::StorageV1::Object',
        name: file_path_2, bucket: "code-path-mappings")
    end

    let(:mapping_files_list) do
      instance_double('Google::Apis::StorageV1::Objects', items:
        [google_api_object_1, google_api_object_2], next_page_token: nil)
    end

    context "when mapping file present for pipeline type" do
      let(:response_from_gcs) { { name: "file_name", body: "{}" } }

      before do
        allow(gcs_client).to receive(:list_objects).and_return(mapping_files_list)
        allow(gcs_client).to receive(:get_object).with(gcs_bucket_name, String).and_return(response_from_gcs)
      end

      it 'calls get_object with correct mapping file path' do
        expect(gcs_client).to receive(:get_object).with(gcs_bucket_name, file_path_2)
        code_paths_mapping.import(branch, run_type)
      end
    end

    context "when mapping file cannot be retrieved" do
      before do
        allow(code_paths_mapping).to receive(:code_paths_mapping_file).and_return(nil)
        allow(gcs_client).to receive(:get_object).with(gcs_bucket_name, nil).and_raise(ArgumentError)
      end

      it 'logs the error and does not raise an exception' do
        expect(logger).to receive(:error).with("Failed to download code paths mapping from GCS. Error: ArgumentError")
        expect(logger).to receive(:error).with(/Backtrace: \[.*/)
        code_paths_mapping.import(branch, run_type)
      end
    end
  end
end
