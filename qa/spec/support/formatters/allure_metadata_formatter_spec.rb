# frozen_string_literal: true

describe QA::Support::Formatters::AllureMetadataFormatter do
  include QA::Support::Helpers::StubEnv

  let(:formatter) { described_class.new(StringIO.new) }

  let(:rspec_example_notification) do
    instance_double(
      RSpec::Core::Notifications::FailedExampleNotification,
      example: rspec_example,
      message_lines: ["Some failure", "message"]
    )
  end

  # rubocop:disable RSpec/VerifiedDoubles -- verified double complains about missing dynamically added methods
  let(:rspec_example) do
    double(
      RSpec::Core::Example,
      tms: nil,
      issue: nil,
      add_link: nil,
      set_flaky: nil,
      parameter: nil,
      attempts: 0,
      file_path: 'spec.rb',
      execution_result: instance_double(RSpec::Core::Example::ExecutionResult, status: status),
      metadata: {
        testcase: 'testcase',
        quarantine: { issue: 'issue' }
      },
      exception: RSpec::Expectations::ExpectationNotMetError.new("Some failure message")
    )
  end
  # rubocop:enable RSpec/VerifiedDoubles

  let(:ci_job) { 'ee:relative 5' }
  let(:ci_job_url) { 'url' }
  let(:status) { :failed }

  before do
    stub_env('CI', 'true')
    stub_env('CI_JOB_NAME', ci_job)
    stub_env('CI_JOB_URL', ci_job_url)
  end

  context 'with links' do
    it 'adds quarantine, failure issue and ci job links', :aggregate_failures do
      formatter.example_finished(rspec_example_notification)

      expect(rspec_example).to have_received(:issue).with('Quarantine issue', 'issue')
      expect(rspec_example).to have_received(:add_link).with(name: "Job(#{ci_job})", url: ci_job_url)
      expect(rspec_example).to have_received(:issue).with(
        'Failure issues',
        'https://gitlab.com/gitlab-org/quality/e2e-test-issues/-/issues?sort=updated_desc&scope=all&state=opened&' \
          'search=spec.rb&search=Some%20failure%0Amessage'
      )
    end

    context 'when message_lines is empty' do
      let(:rspec_example_notification) do
        instance_double(
          RSpec::Core::Notifications::FailedExampleNotification,
          example: rspec_example,
          message_lines: []
        )
      end

      it 'uses exception message for the search URL', :aggregate_failures do
        formatter.example_finished(rspec_example_notification)

        expect(rspec_example).to have_received(:issue).with(
          'Failure issues',
          'https://gitlab.com/gitlab-org/quality/e2e-test-issues/-/issues?sort=updated_desc&scope=all&state=opened&' \
            'search=spec.rb&search=Some%20failure%20message'
        )
      end
    end
  end
end
