# frozen_string_literal: true

describe QA::Support::Formatters::CoverbandFormatter do
  include QA::Support::Helpers::StubEnv

  let(:formatter) { described_class.new(StringIO.new) }

  let(:rspec_example_notification) do
    instance_double(RSpec::Core::Notifications::ExampleNotification, example: rspec_example)
  end

  let(:rspec_example) do
    instance_double(
      RSpec::Core::Example,
      file_path: 'create_issue_spec.rb',
      execution_result: instance_double(RSpec::Core::Example::ExecutionResult, status: status),
      metadata: {
        testcase: 'testcase',
        full_description: "Plan",
        location: "./qa/specs/features/browser_ui/2_plan/issue/create_issue_spec.rb:5"
      }
    )
  end

  let(:gitlab_address) { 'http://gitlab.test.com' }
  let(:api_path) { "#{gitlab_address}/api/v4/internal/coverage" }
  let(:status) { :failed }
  let(:token_header) { { "PRIVATE-TOKEN" => 'token' } }
  let(:logger) { instance_double(ActiveSupport::Logger, debug: true, error: true, info: true) }
  let(:api_response) { instance_double(::RestClient::Response, code: code, body: body) }
  let(:code) { 200 }
  let(:body) { '[]' }

  let(:mapping) do
    { "./qa/specs/features/browser_ui/2_plan/issue/create_issue_spec.rb:5": { "test mapping": 1 } }
  end

  before do
    stub_env('GITLAB_QA_ADMIN_ACCESS_TOKEN', 'token')

    allow(QA::Runtime::Logger).to receive(:logger).and_return(logger)
    allow(QA::Runtime::Scenario).to receive(:gitlab_address).and_return(gitlab_address)
    allow(::RestClient::Request).to receive(:execute).and_return(api_response)
  end

  context 'with example_started' do
    context 'when success response' do
      it 'logs coverage cleared', :aggregate_failures do
        formatter.example_started(rspec_example_notification)

        expect(logger).to have_received(:info).with("Cleared coverage data").once
      end
    end

    context 'with failure response' do
      let(:code) { 401 }

      before do
        allow(QA::Support::Retrier).to receive(:retry_until).and_wrap_original do |method, *_args, &block|
          method.call(max_attempts: 1, &block)
        end
      end

      it 'logs error message' do
        formatter.example_started(rspec_example_notification)

        expect(logger).to have_received(:error).with("Failed to clear coverage, code: #{code}, body: #{body}").once
      end
    end
  end

  context 'when example finished' do
    context 'with success response and non empty coverage' do
      let(:status) { :passed }
      let(:body) { '{"test mapping":1}' }

      it 'logs success message and does not log any errors' do
        formatter.example_finished(rspec_example_notification)

        expect(logger).not_to have_received(:error)
        expect(logger).to have_received(:info).with("Fetched coverage data").once
      end
    end

    context 'with failure response' do
      let(:status) { :passed }
      let(:code) { 401 }

      before do
        allow(QA::Support::Retrier).to receive(:retry_until).and_wrap_original do |method, *_args, &block|
          method.call(max_attempts: 1, &block)
        end
      end

      it 'logs error message' do
        formatter.example_finished(rspec_example_notification)

        expect(logger).to have_received(:error)
          .with("Failed to fetch coverage data, code: #{code}, body: #{body}")
          .once
      end
    end
  end

  context 'when save_test_mapping is called' do
    let(:file_name_pattern) { "test-code-paths-mapping-job-name" }

    before do
      stub_env('CI_JOB_NAME_SLUG', 'job-name')
    end

    context 'with mapping data present' do
      before do
        allow(formatter).to receive(:test_mapping).and_return(mapping)
        allow(::File).to receive(:write)
      end

      it 'writes to file' do
        formatter.save_test_mapping

        expect(::File).to have_received(:write).with(/#{file_name_pattern}/, mapping.to_json).once
        expect(logger).to have_received(:info).with(/Saved test coverage mapping data to \S+\.json/).once
      end
    end

    context 'when writing to file throws an error' do
      before do
        allow(::File).to receive(:write).and_raise("some error")
      end

      it 'raises an error' do
        formatter.save_test_mapping

        expect(logger).to have_received(:error)
          .with("Failed to save test coverage mapping data, error: some error")
          .once
      end
    end
  end
end
