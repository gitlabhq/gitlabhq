# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'

# We need to capture pid from Process.spawn and then clean up by killing the process, which requires instance variables.
# rubocop: disable RSpec/InstanceVariable
RSpec.describe 'bin/diagnostic-reports-uploader', :uses_fast_spec_helper_but_runs_slow do
  # This is a smoke test for 'bin/diagnostic-reports-uploader'.
  # We intend to run this binary with `ruby bin/diagnostic-reports-uploader`, without preloading the entire Rails app.
  # Also, we use inline gemfile, to avoid pulling full Gemfile from the main app into memory.
  # The goal of that test is to confirm that the binary starts that way.
  # The implementation logic is covered in 'spec/bin/diagnostic_reports_uploader_spec.rb'
  include FastRailsRoot

  let(:gcs_bucket) { 'test_bucket' }
  let(:gcs_project) { 'test_project' }
  let(:gcs_key) { Tempfile.new }
  let(:reports_dir) { Dir.mktmpdir }
  let(:report) { Tempfile.new('report.json', reports_dir) }

  let(:env) do
    {
      'GITLAB_DIAGNOSTIC_REPORTS_BUCKET' => gcs_bucket,
      'GITLAB_DIAGNOSTIC_REPORTS_PROJECT' => gcs_project,
      'GITLAB_GCP_KEY_PATH' => gcs_key.path,
      'GITLAB_DIAGNOSTIC_REPORTS_PATH' => reports_dir,
      'GITLAB_DIAGNOSTIC_REPORTS_UPLOADER_SLEEP_S' => '1'
    }
  end

  before do
    gcs_key.write(
      {
        type: "service_account",
        client_email: 'test@gitlab.com',
        private_key_id: "test_id",
        private_key: File.read(rails_root_join('spec/fixtures/ssl_key.pem'))
      }.to_json
    )
    gcs_key.rewind

    FileUtils.touch(report.path)
  end

  after do
    if @pid
      Timeout.timeout(10) do
        Process.kill('TERM', @pid)
        Process.waitpid(@pid)
      end
    end
  rescue Errno::ESRCH, Errno::ECHILD => _
    # 'No such process' or 'No child processes' means the process died before
  ensure
    gcs_key.unlink
    FileUtils.rm_rf(reports_dir, secure: true)
  end

  it 'starts successfully', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/448411' do
    expect(File.exist?(report.path)).to be true

    bin_path = rails_root_join("bin/diagnostic-reports-uploader")

    cmd = ['bundle', 'exec', 'ruby', bin_path]
    @pid = Process.spawn(env, *cmd)

    expect(Gitlab::ProcessManagement.process_alive?(@pid)).to be true

    expect do
      Timeout.timeout(10) do
        # Uploader will remove the file, no matter the upload result. We are waiting for exactly that.
        # The report being removed means the uploader loop works. We are not attempting real upload.
        attempted_upload_and_cleanup = false
        until attempted_upload_and_cleanup
          sleep 1
          attempted_upload_and_cleanup = !File.exist?(report.path)
        end
      end
    end.not_to raise_error
  end
end
# rubocop: enable RSpec/InstanceVariable
