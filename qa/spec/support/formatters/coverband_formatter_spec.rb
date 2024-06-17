# frozen_string_literal: true

describe QA::Support::Formatters::CoverbandFormatter do
  include QA::Support::Helpers::StubEnv

  let(:formatter) { described_class.new(StringIO.new) }

  let(:rspec_example_notification) do
    instance_double(RSpec::Core::Notifications::ExampleNotification, example: rspec_example)
  end

  # rubocop:disable RSpec/VerifiedDoubles -- Custom object

  let(:rspec_example) do
    double(
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

  # rubocop:enable RSpec/VerifiedDoubles

  let(:gitlab_address) { 'http://gitlab.test.com' }
  let(:api_path) { "#{gitlab_address}/api/v4/internal/coverage" }

  let(:status) { :failed }
  let(:token_header) { { "PRIVATE-TOKEN" => 'token' } }
  let(:api_response) do
    instance_double(
      ::RestClient::Response
    )
  end

  let(:non_empty_response) do
    '{"test mapping":1}'
  end

  let(:mapping) do
    { "./qa/specs/features/browser_ui/2_plan/issue/create_issue_spec.rb:5": { "test mapping": 1 } }
  end

  before do
    stub_env('GITLAB_QA_ADMIN_ACCESS_TOKEN', 'token')
  end

  context 'with example_started' do
    before do
      allow(QA::Runtime::Scenario).to receive(:gitlab_address).and_return(gitlab_address)
      allow(api_response).to receive(:body).and_return({})
      allow(::RestClient::Request).to receive(:execute).and_return(api_response)
    end

    context 'when success response' do
      before do
        allow(api_response).to receive(:code).and_return(200)
      end

      it 'logs coverage cleared', :aggregate_failures do
        expect(QA::Runtime::Logger.logger).to receive(:debug).with("Cleared coverage data before example starts").once
        formatter.example_started(rspec_example_notification)
      end
    end

    context 'with failure response' do
      before do
        allow(api_response).to receive(:code).and_return(401)
        allow(QA::Support::Retrier).to receive(:retry_until).and_wrap_original do |method|
          method.call(max_attempts: 1)
        end
      end

      it 'logs error message' do
        expect(QA::Runtime::Logger.logger).to receive(:error).with(/Failed to clear coverage.*/).once
        formatter.example_started(rspec_example_notification)
      end
    end
  end

  context 'when example finished' do
    before do
      allow(QA::Runtime::Scenario).to receive(:gitlab_address).and_return(gitlab_address)
      allow(::RestClient::Request).to receive(:execute).and_return(api_response)
    end

    context 'with success response and non empty coverage' do
      let(:status) { :passed }

      before do
        allow(api_response).to receive(:code).and_return(200)
        allow(api_response).to receive(:body).and_return(non_empty_response)
      end

      it 'logs success message and does not log any errors' do
        expect(QA::Runtime::Logger.logger).not_to receive(:error)
        expect(QA::Runtime::Logger.logger).to receive(:debug).with("Coverage paths were stored in mapping hash").once
        formatter.example_finished(rspec_example_notification)
      end
    end

    context 'with failure response' do
      let(:status) { :passed }

      before do
        allow(api_response).to receive(:code).and_return(401)
        allow(api_response).to receive(:body).and_return({})
        allow(QA::Support::Retrier).to receive(:retry_until).and_wrap_original do |method|
          method.call(max_attempts: 1)
        end
      end

      it 'logs error message' do
        expect(QA::Runtime::Logger.logger).to receive(:error).with(/Failed to fetch coverage mapping.*/).once
        formatter.example_finished(rspec_example_notification)
      end
    end
  end

  context 'when save_test_mapping is called' do
    before do
      stub_env('CI_JOB_NAME_SLUG', 'job-name')
    end

    let(:file_name_pattern) { "test-code-paths-mapping-job-name" }

    context 'with mapping data present' do
      before do
        allow(formatter).to receive(:test_mapping).and_return(mapping)
      end

      it 'writes to file' do
        expect(::File).to receive(:write).with(/#{file_name_pattern}/, mapping.to_json).once
        expect(QA::Runtime::Logger.logger).to receive(:debug).with(/Saved test code paths mapping to.*/).once
        formatter.save_test_mapping
      end
    end

    context 'when writing to file throws an error' do
      before do
        allow(::File).to receive(:write).and_raise(StandardError)
      end

      it 'raises an error' do
        expect(QA::Runtime::Logger.logger).to receive(:error)
          .with(/Failed to save test code paths mapping, error:.*/).once
        formatter.save_test_mapping
      end
    end
  end
end
