# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'

RSpec.describe 'bin/diagnostic-reports-uploader' do
  let(:reports_dir) { Dir.mktmpdir }
  let(:gcs_key) { Tempfile.new }
  let(:gcs_project) { 'test_gcs_project' }
  let(:gcs_bucket) { 'test_gcs_bucket' }

  after do
    FileUtils.remove_entry(reports_dir)
    FileUtils.remove_entry(gcs_key)
  end

  subject(:load_bin) { load File.expand_path('../../bin/diagnostic-reports-uploader', __dir__) }

  context 'when necessary ENV vars are set' do
    before do
      stub_env('GITLAB_DIAGNOSTIC_REPORTS_PATH', reports_dir)
      stub_env('GITLAB_GCP_KEY_PATH', gcs_key.path)
      stub_env('GITLAB_DIAGNOSTIC_REPORTS_PROJECT', gcs_project)
      stub_env('GITLAB_DIAGNOSTIC_REPORTS_BUCKET', gcs_bucket)
    end

    let(:reports_uploader) { instance_double(Gitlab::Memory::ReportsUploader) }
    let(:upload_and_cleanup_reports) { instance_double(Gitlab::Memory::UploadAndCleanupReports) }
    let(:logger) { instance_double(Gitlab::Memory::DiagnosticReportsLogger) }

    it 'runs successfully' do
      expect(Gitlab::Memory::DiagnosticReportsLogger).to receive(:new).and_return(logger)

      expect(Gitlab::Memory::ReportsUploader)
        .to receive(:new).with(gcs_key: gcs_key.path, gcs_project: gcs_project, gcs_bucket: gcs_bucket, logger: logger)
        .and_return(reports_uploader)

      expect(Gitlab::Memory::UploadAndCleanupReports)
        .to receive(:new).with(uploader: reports_uploader, reports_path: reports_dir, logger: logger)
        .and_return(upload_and_cleanup_reports)

      expect(upload_and_cleanup_reports).to receive(:call)

      load_bin
    end
  end

  context 'when GITLAB_DIAGNOSTIC_REPORTS_PATH is missing' do
    it 'raises RuntimeError' do
      expect { load_bin }.to raise_error(RuntimeError, 'GITLAB_DIAGNOSTIC_REPORTS_PATH dir is missing')
    end
  end

  context 'when GITLAB_GCP_KEY_PATH is missing' do
    before do
      stub_env('GITLAB_DIAGNOSTIC_REPORTS_PATH', reports_dir)
    end

    it 'raises RuntimeError' do
      expect { load_bin }.to raise_error(RuntimeError, /GCS keyfile not found/)
    end
  end

  context 'when GITLAB_DIAGNOSTIC_REPORTS_PROJECT is missing' do
    before do
      stub_env('GITLAB_DIAGNOSTIC_REPORTS_PATH', reports_dir)
      stub_env('GITLAB_GCP_KEY_PATH', gcs_key.path)
    end

    it 'raises RuntimeError' do
      expect { load_bin }.to raise_error(RuntimeError, 'GITLAB_DIAGNOSTIC_REPORTS_PROJECT is missing')
    end
  end

  context 'when GITLAB_DIAGNOSTIC_REPORTS_BUCKET is missing' do
    before do
      stub_env('GITLAB_DIAGNOSTIC_REPORTS_PATH', reports_dir)
      stub_env('GITLAB_GCP_KEY_PATH', gcs_key.path)
      stub_env('GITLAB_DIAGNOSTIC_REPORTS_PROJECT', gcs_project)
    end

    it 'raises RuntimeError' do
      expect { load_bin }.to raise_error(RuntimeError, 'GITLAB_DIAGNOSTIC_REPORTS_BUCKET is missing')
    end
  end
end
