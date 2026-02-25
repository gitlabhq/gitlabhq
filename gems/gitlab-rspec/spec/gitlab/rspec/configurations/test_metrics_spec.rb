# frozen_string_literal: true

require 'logger'
require 'gitlab/rspec/stub_env'
require 'gitlab/rspec/configurations/test_metrics'

RSpec.describe Gitlab::Rspec::Configurations::TestMetrics do
  include StubENV

  describe '.configure!' do
    let(:rspec_config) { instance_double(RSpec::Core::Configuration, dry_run?: false) }
    let(:exporter_config) do
      instance_double(
        GitlabQuality::TestTooling::TestMetricsExporter::Config,
        logger: logger,
        'run_type=': nil,
        'custom_metrics_proc=': nil,
        'clickhouse_config=': nil
      )
    end

    let!(:original_logger) { described_class.instance_variable_get(:@logger) }
    let(:logger) { instance_double(Logger, warn: nil, info: nil, error: nil, debug: nil) }

    let(:all_env_vars) do
      {
        'CI' => 'true',
        'GLCI_EXPORT_TEST_METRICS' => 'true',
        'GLCI_TEST_METRICS_RUN_TYPE' => 'rspec',
        'GLCI_DA_CLICKHOUSE_URL' => 'http://localhost:8123',
        'GLCI_CLICKHOUSE_METRICS_USERNAME' => 'user',
        'GLCI_CLICKHOUSE_METRICS_PASSWORD' => 'pass',
        'GLCI_CLICKHOUSE_METRICS_DB' => 'metrics_db',
        'GLCI_CLICKHOUSE_METRICS_TABLE' => 'metrics_table',
        'GLCI_CLICKHOUSE_SHARED_DB' => 'shared_db'
      }
    end

    before do
      described_class.instance_variable_set(:@run_type, nil)
      described_class.instance_variable_set(:@logger, logger)

      all_env_vars.each { |key, value| stub_env(key, value) }

      allow(RSpec).to receive(:configure).and_yield(rspec_config)
      allow(GitlabQuality::TestTooling::TestMetricsExporter::Config).to receive(:configure).and_yield(exporter_config)
      allow(rspec_config).to receive(:add_formatter)
    end

    after do
      # on ci test_metrics export is setup for the test process running this test,
      # so we need to ensure class instance variable is restored to original state
      described_class.instance_variable_set(:@logger, original_logger)
    end

    context 'when all required environment variables are set' do
      it 'registers the formatter' do
        described_class.configure!

        expect(rspec_config).to have_received(:add_formatter)
          .with(GitlabQuality::TestTooling::TestMetricsExporter::Formatter)
      end
    end

    context 'when export is not enabled' do
      before do
        stub_env('GLCI_EXPORT_TEST_METRICS', nil)
      end

      it 'does not configure anything' do
        described_class.configure!

        expect(RSpec).not_to have_received(:configure)
      end
    end

    described_class::REQUIRED_CLICKHOUSE_ENV_VARS.each do |var|
      context "when #{var} is missing" do
        before do
          stub_env(var, nil)
        end

        it 'logs a warning and does not register the formatter' do
          described_class.configure!

          expect(logger).to have_received(:warn).with(/#{var}/)
          expect(rspec_config).not_to have_received(:add_formatter)
        end
      end
    end

    context 'when multiple variables are missing' do
      before do
        stub_env('GLCI_CLICKHOUSE_SHARED_DB', nil)
        stub_env('GLCI_CLICKHOUSE_METRICS_DB', nil)
      end

      it 'logs a warning listing all missing variables' do
        described_class.configure!

        expect(logger).to have_received(:warn).with(
          a_string_including('GLCI_CLICKHOUSE_METRICS_DB', 'GLCI_CLICKHOUSE_SHARED_DB')
        )
        expect(rspec_config).not_to have_received(:add_formatter)
      end
    end
  end

  describe '.pipeline_type' do
    subject(:pipeline_type) { described_class.send(:pipeline_type) }

    before do
      described_class.instance_variable_set(:@pipeline_type, nil)
    end

    context 'when on default branch with SCHEDULE_TYPE' do
      before do
        stub_env('CI_COMMIT_REF_NAME', 'master')
        stub_env('CI_DEFAULT_BRANCH', 'master')
        stub_env('SCHEDULE_TYPE', 'nightly')
      end

      it { is_expected.to eq('default_branch_scheduled_pipeline') }
    end

    context 'when on default branch without SCHEDULE_TYPE' do
      before do
        stub_env('CI_COMMIT_REF_NAME', 'master')
        stub_env('CI_DEFAULT_BRANCH', 'master')
        stub_env('SCHEDULE_TYPE', nil)
      end

      it { is_expected.to eq('default_branch_pipeline') }
    end

    context 'when on a stable-ee branch' do
      before do
        stub_env('CI_COMMIT_REF_NAME', '17-5-stable-ee')
        stub_env('CI_DEFAULT_BRANCH', 'master')
      end

      it { is_expected.to eq('stable_branch_pipeline') }
    end

    context 'when targeting a stable-ee branch' do
      before do
        stub_env('CI_COMMIT_REF_NAME', 'some-backport-branch')
        stub_env('CI_DEFAULT_BRANCH', 'master')
        stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_NAME', '17-5-stable-ee')
      end

      it { is_expected.to eq('backport_merge_request_pipeline') }
    end

    context 'when CI_MERGE_REQUEST_IID is present' do
      before do
        stub_env('CI_COMMIT_REF_NAME', 'feature-branch')
        stub_env('CI_DEFAULT_BRANCH', 'master')
        stub_env('CI_MERGE_REQUEST_IID', '12345')
      end

      it { is_expected.to eq('merge_request_pipeline') }
    end

    context 'when CI_PIPELINE_SOURCE is pipeline (downstream/child)' do
      before do
        stub_env('CI_COMMIT_REF_NAME', 'as-if-foss/feature-branch')
        stub_env('CI_DEFAULT_BRANCH', 'master')
        stub_env('CI_MERGE_REQUEST_IID', nil)
        stub_env('CI_PIPELINE_SOURCE', 'pipeline')
      end

      it { is_expected.to eq('downstream_pipeline') }
    end

    context 'when no conditions match' do
      before do
        stub_env('CI_COMMIT_REF_NAME', 'some-random-branch')
        stub_env('CI_DEFAULT_BRANCH', 'master')
        stub_env('CI_MERGE_REQUEST_IID', nil)
        stub_env('CI_PIPELINE_SOURCE', 'push')
      end

      it { is_expected.to eq('unknown') }
    end
  end
end
