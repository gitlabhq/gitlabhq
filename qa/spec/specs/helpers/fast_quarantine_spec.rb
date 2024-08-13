# frozen_string_literal: true

RSpec.describe QA::Specs::Helpers::FastQuarantine do
  include QA::Support::Helpers::StubEnv

  let(:quarantine_file) { "fast_quarantine-gitlab.txt" }
  let(:response) { instance_double(RestClient::Response, code: 200, body: fq_contents) }
  let(:fq_path) { File.join(QA::Runtime::Path.qa_root, "tmp", quarantine_file) }
  let(:fq_contents) { "fast_quarantine_contents" }

  before do
    stub_env("CI", "true")

    allow(RSpec).to receive(:configure)
    allow(File).to receive(:write).with(fq_path, fq_contents)
    allow(RestClient::Request).to receive(:execute).and_return(response)

    # silence log messages during test execution
    allow(QA::Runtime::Logger).to receive(:logger).and_return(instance_double(ActiveSupport::Logger, debug: nil))
    allow(QA::Runtime::Logger).to receive(:debug)
  end

  it "configures fast quarantine, using defaults" do
    ENV.delete('RSPEC_FAST_QUARANTINE_FILE') # ensure variable is not set if other test is run first
    described_class.configure!

    expect(File).to have_received(:write).with(fq_path, fq_contents)
    expect(RestClient::Request).to have_received(:execute).with(
      method: :get,
      url: "https://gitlab-org.gitlab.io/quality/engineering-productivity/fast-quarantine/rspec/fast_quarantine-gitlab.txt",
      verify_ssl: true
    )
  end

  it "configures with 'RSPEC_FAST_QUARANTINE_FILE'" do
    download_file = 'fast_quarantine-dedicated.txt'
    ENV['RSPEC_FAST_QUARANTINE_FILE'] = download_file

    described_class.configure!

    expect(File).to have_received(:write).with(fq_path, fq_contents)
    expect(RestClient::Request).to have_received(:execute).with(
      method: :get,
      url: "https://gitlab-org.gitlab.io/quality/engineering-productivity/fast-quarantine/rspec/#{download_file}",
      verify_ssl: true
    )
  end
end
