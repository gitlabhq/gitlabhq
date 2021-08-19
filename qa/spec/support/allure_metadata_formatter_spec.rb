# frozen_string_literal: true

describe QA::Support::AllureMetadataFormatter do
  include Helpers::StubENV

  let(:formatter) { described_class.new(StringIO.new) }

  let(:rspec_example_notification) { double('RSpec::Core::Notifications::ExampleNotification', example: rspec_example) }
  let(:rspec_example) do
    double(
      'RSpec::Core::Example',
      tms: nil,
      issue: nil,
      add_link: nil,
      attempts: 0,
      file_path: 'file/path/spec.rb',
      metadata: {
        testcase: 'testcase',
        quarantine: { issue: 'issue' }
      }
    )
  end

  let(:ci_job) { 'ee:relative 5' }
  let(:ci_job_url) { 'url' }

  before do
    stub_env('CI', 'true')
    stub_env('CI_JOB_NAME', ci_job)
    stub_env('CI_JOB_URL', ci_job_url)
  end

  it "adds additional data to report" do
    formatter.example_started(rspec_example_notification)

    aggregate_failures do
      expect(rspec_example).to have_received(:tms).with('Testcase', 'testcase')
      expect(rspec_example).to have_received(:issue).with('Quarantine issue', 'issue')
      expect(rspec_example).to have_received(:add_link).with(name: "Job(#{ci_job})", url: ci_job_url)
      expect(rspec_example).to have_received(:issue).with(
        'Failure issues',
        'https://gitlab.com/gitlab-org/gitlab/-/issues?scope=all&state=opened&search=spec.rb'
      )
    end
  end
end
