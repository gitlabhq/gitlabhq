# frozen_string_literal: true
require 'active_support/testing/time_helpers'
RSpec.describe QA::Tools::TestResourceDataProcessor do
  include QA::Support::Helpers::StubEnv
  include ActiveSupport::Testing::TimeHelpers

  subject(:processor) { Class.new(described_class).instance }

  let(:info) { 'information' }
  let(:api_response) { {} }
  let(:method) { :api }
  let(:time) { 2 }
  let(:api_path) { resource.api_delete_path }
  let(:resource) { QA::Resource::Project.init { |project| project.id = 1 } }

  let(:result) do
    {
      'QA::Resource::Project' => [{
        info: info,
        api_path: api_path,
        fabrication_method: method,
        fabrication_time: time,
        http_method: :post,
        timestamp: Time.now.to_s
      }]
    }
  end

  before do
    processor.collect(resource: resource, info: info, fabrication_method: method, fabrication_time: time)
  end

  around do |example|
    freeze_time { example.run }
  end

  describe '.collect' do
    it 'collects and stores resource' do
      expect(processor.resources).to eq(result)
    end
  end

  describe '.write_to_file' do
    using RSpec::Parameterized::TableSyntax

    where(:ci, :suite_failed, :retry_failed_specs, :rspec_retried, :file_path) do
      true  | true  | false | false | 'root/tmp/failed-test-resources-random.json'
      true  | false | false | false | 'root/tmp/test-resources-random.json'
      false | true  | false | false | 'root/tmp/failed-test-resources.json'
      false | false | false | false | 'root/tmp/test-resources.json'
      false | true  | true  | false | 'root/tmp/test-resources.json'
      false | true  | true  | true  | 'root/tmp/failed-test-resources.json'
    end

    with_them do
      let(:resources_file) { Pathname.new(file_path) }

      before do
        allow(QA::Runtime::Env).to receive(:running_in_ci?).and_return(ci)
        allow(QA::Runtime::Env).to receive(:rspec_retried?).and_return(rspec_retried)
        allow(QA::Runtime::Path).to receive(:qa_root).and_return('root')
        allow(::Gitlab::QA::Runtime::Env).to receive(:retry_failed_specs?).and_return(retry_failed_specs)
        allow(File).to receive(:write)
        allow(SecureRandom).to receive(:hex).with(any_args).and_return('random')
      end

      it 'writes applicable resources to file' do
        processor.write_to_file(suite_failed)

        expect(File).to have_received(:write).with(resources_file, JSON.pretty_generate(result))
      end
    end
  end
end
