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
      let(:body) { '{"app/models/user.rb":{"1":"5","2":"10"},"app/controllers/application_controller.rb":{"1":"3"}}' }

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

  context 'when save_coverage_data is called' do
    let(:mapping_file_pattern) { "test-code-paths-mapping-job-name" }
    let(:coverage_file_pattern) { "coverband-coverage-job-name" }
    let(:full_coverage) do
      {
        "./qa/specs/features/browser_ui/2_plan/issue/create_issue_spec.rb:5" => {
          "app/models/user.rb" => { "1" => "5" }
        }
      }
    end

    before do
      stub_env('CI_JOB_NAME_SLUG', 'job-name')
      allow(formatter).to receive(:full_coverage_by_example).and_return(full_coverage)
    end

    context 'with coverage data present' do
      before do
        allow(::File).to receive(:write)
      end

      it 'writes both mapping and full coverage files' do
        formatter.send(:save_coverage_data)

        expect(::File).to have_received(:write).with(/#{mapping_file_pattern}/, anything).once
        expect(::File).to have_received(:write).with(/#{coverage_file_pattern}/, full_coverage.to_json).once
        expect(logger).to have_received(:info).with(/Saved test coverage mapping data to \S+\.json/).once
        expect(logger).to have_received(:info).with(/Saved full Coverband coverage data to \S+\.json/).once
      end
    end

    context 'with empty coverage data' do
      before do
        allow(formatter).to receive(:full_coverage_by_example).and_return({})
        allow(::File).to receive(:write)
      end

      it 'does not write any files' do
        formatter.send(:save_coverage_data)

        expect(::File).not_to have_received(:write)
        expect(logger).not_to have_received(:info)
      end
    end

    context 'when writing to file throws an error' do
      before do
        allow(::File).to receive(:write).and_raise("some error")
      end

      it 'logs error message' do
        formatter.send(:save_coverage_data)

        expect(logger).to have_received(:error)
          .with("Failed to save coverage data, error: some error")
          .once
      end
    end
  end
end
