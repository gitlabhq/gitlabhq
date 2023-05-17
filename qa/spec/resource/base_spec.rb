# frozen_string_literal: true

RSpec.describe QA::Resource::Base do
  include QA::Support::Helpers::StubEnv

  let(:resource) { spy('resource') }
  let(:api_client) { instance_double('Runtime::API::Client') }
  let(:location) { 'http://location' }
  let(:log_regex) { %r{==> Built a MyResource with username 'qa' via #{method} in [\d.\-e]+ seconds+} }

  before do
    allow(QA::Tools::TestResourceDataProcessor).to receive(:collect)
    allow(QA::Tools::TestResourceDataProcessor).to receive(:write_to_file)
  end

  shared_context 'with simple resource' do
    subject do
      Class.new(QA::Resource::Base) do
        def self.name
          'MyResource'
        end

        attribute :test do
          'block'
        end

        attribute :token do
          'token_value'
        end

        attribute :username do
          'qa'
        end

        attribute :no_block

        def fabricate!(*args)
          'any'
        end

        def self.current_url
          'http://stub'
        end
      end
    end

    let(:resource) { subject.new }
  end

  shared_context 'with fabrication context' do
    subject do
      Class.new(described_class) do
        def self.name
          'MyResource'
        end
      end
    end

    before do
      allow(subject).to receive(:current_url).and_return(location)
      allow(subject).to receive(:new).and_return(resource)
    end
  end

  shared_examples 'fabrication method' do |fabrication_method_called, actual_fabrication_method = nil|
    let(:fabrication_method_used) { actual_fabrication_method || fabrication_method_called }

    it 'yields resource before calling resource method' do
      expect(resource).to receive(:something!).ordered
      expect(resource).to receive(fabrication_method_used).ordered.and_return(location)

      subject.public_send(fabrication_method_called, resource: resource, &:something!)
    end
  end

  describe '.fabricate!' do
    context 'when resource does not support fabrication via the API' do
      before do
        allow(described_class).to receive(:fabricate_via_api!).and_raise(NotImplementedError)
      end

      it 'calls .fabricate_via_browser_ui!' do
        expect(described_class).to receive(:fabricate_via_browser_ui!)

        described_class.fabricate!
      end
    end

    context 'when resource supports fabrication via the API' do
      it 'calls .fabricate_via_api!!' do
        expect(described_class).to receive(:fabricate_via_api!)

        described_class.fabricate!
      end
    end

    context 'when personal_access_tokens_disabled returns true' do
      before do
        stub_env('PERSONAL_ACCESS_TOKENS_DISABLED', true)
      end

      it 'calls .fabricate_via_browser_ui!' do
        expect(described_class).to receive(:fabricate_via_browser_ui!)

        described_class.fabricate!
      end
    end
  end

  describe '.fabricate_via_api_unless_fips!' do
    context 'when personal_access_tokens_disabled returns false' do
      it 'calls .fabricate_via_api!!' do
        expect(described_class).to receive(:fabricate_via_api!)

        described_class.fabricate_via_api_unless_fips!
      end
    end

    context 'when personal_access_tokens_disabled returns true' do
      before do
        stub_env('PERSONAL_ACCESS_TOKENS_DISABLED', true)
      end

      it 'calls .fabricate_via_browser_ui!' do
        expect(described_class).to receive(:fabricate_via_browser_ui!)

        described_class.fabricate_via_api_unless_fips!
      end
    end
  end

  describe '.fabricate_via_api!' do
    context 'when fabricating' do
      include_context 'with fabrication context'

      it_behaves_like 'fabrication method', :fabricate_via_api!

      it 'instantiates the resource, calls resource method returns the resource' do
        expect(resource).to receive(:fabricate_via_api!).and_return(location)

        result = subject.fabricate_via_api!(resource: resource, parents: [])

        expect(result).to eq(resource)
      end
    end

    context "with debug log level" do
      include_context 'with simple resource'

      let(:method) { 'api' }

      before do
        allow(QA::Runtime::Logger).to receive(:info)
        allow(resource).to receive(:api_support?).and_return(true)
        allow(resource).to receive(:fabricate_via_api!)
        allow(resource).to receive(:api_client) { api_client }
      end

      it 'logs the resource and build method' do
        subject.fabricate_via_api!('something', resource: resource, parents: [])

        expect(QA::Runtime::Logger).to have_received(:info) do |&msg|
          expect(msg.call).to match_regex(log_regex)
        end
      end
    end
  end

  describe '.fabricate_via_browser_ui!' do
    context 'when fabricating' do
      include_context 'with fabrication context'

      it_behaves_like 'fabrication method', :fabricate_via_browser_ui!, :fabricate!

      it 'instantiates the resource and calls resource method' do
        subject.fabricate_via_browser_ui!('something', resource: resource, parents: [])

        expect(resource).to have_received(:fabricate!).with('something')
      end

      it 'returns fabrication resource' do
        result = subject.fabricate_via_browser_ui!('something', resource: resource, parents: [])

        expect(result).to eq(resource)
      end
    end

    context "with debug log level" do
      include_context 'with simple resource'

      let(:method) { 'browser_ui' }

      before do
        allow(QA::Runtime::Logger).to receive(:info)
      end

      it 'logs the resource and build method' do
        subject.fabricate_via_browser_ui!('something', resource: resource, parents: [])

        expect(QA::Runtime::Logger).to have_received(:info) do |&msg|
          expect(msg.call).to match_regex(log_regex)
        end
      end
    end
  end

  describe '.attribute' do
    include_context 'with simple resource'

    context 'when the attribute is populated via a block' do
      it 'returns value from the block' do
        result = subject.fabricate!(resource: resource)

        expect(result).to be_a(described_class)
        expect(result.test).to eq('block')
      end
    end

    context 'when the attribute is populated via the api' do
      let(:api_resource) { { no_block: 'api' } }

      before do
        allow(resource).to receive(:api_resource).and_return(api_resource)
      end

      it 'returns value from api' do
        result = subject.fabricate!(resource: resource)

        expect(result).to be_a(described_class)
        expect(result.no_block).to eq('api')
      end

      context 'when the attribute also has a block' do
        let(:api_resource) { { test: 'api_with_block' } }

        before do
          allow(QA::Runtime::Logger).to receive(:debug)
        end

        it 'returns value from api and emits an debug log entry' do
          result = subject.fabricate!(resource: resource)

          expect(result).to be_a(described_class)
          expect(result.test).to eq('api_with_block')
          expect(QA::Runtime::Logger)
            .to have_received(:debug).with(/api_with_block/)
        end
      end

      context 'when the attribute is token and has a block' do
        let(:api_resource) { { token: 'another_token_value' } }

        before do
          allow(QA::Runtime::Logger).to receive(:debug)
        end

        it 'emits a masked debug log entry' do
          result = subject.fabricate!(resource: resource)

          expect(result).to be_a(described_class)
          expect(result.token).to eq('another_token_value')

          expect(QA::Runtime::Logger)
            .to have_received(:debug).with(/MASKED/)
        end
      end
    end

    context 'when the attribute is populated via direct assignment' do
      before do
        resource.test = 'value'
      end

      it 'returns value from the assignment' do
        result = subject.fabricate!(resource: resource)

        expect(result).to be_a(described_class)
        expect(result.test).to eq('value')
      end

      context 'when the api also has such response' do
        before do
          allow(resource).to receive(:api_resource).and_return({ test: 'api' })
        end

        it 'returns value from the assignment' do
          result = subject.fabricate!(resource: resource)

          expect(result).to be_a(described_class)
          expect(result.test).to eq('value')
        end
      end
    end

    context 'when the attribute has no value' do
      it 'raises an error because no values could be found' do
        result = subject.fabricate!(resource: resource)

        expect { result.no_block }.to raise_error(
          described_class::NoValueError, "No value was computed for no_block of #{resource.class.name}."
        )
      end
    end

    context 'when multiple resources have the same attribute name' do
      let(:base) do
        Class.new(QA::Resource::Base) do
          def fabricate!
            'any'
          end

          def self.current_url
            'http://stub'
          end
        end
      end

      let(:first_resource) do
        Class.new(base) do
          attribute :test do
            'first block'
          end
        end
      end

      let(:second_resource) do
        Class.new(base) do
          attribute :test do
            'second block'
          end
        end
      end

      it 'has unique attribute values' do
        first_result = first_resource.fabricate!(resource: first_resource.new)
        second_result = second_resource.fabricate!(resource: second_resource.new)

        expect(first_result.test).to eq 'first block'
        expect(second_result.test).to eq 'second block'
      end
    end
  end

  describe '#web_url' do
    include_context 'with simple resource'

    it 'sets #web_url to #current_url after fabrication' do
      subject.fabricate!(resource: resource)

      expect(resource.web_url).to eq(subject.current_url)
    end
  end

  describe '#visit!' do
    include_context 'with simple resource'

    let(:wait_for_requests_class) { QA::Support::WaitForRequests }

    before do
      allow(resource).to receive(:visit)
    end

    it 'calls #visit with the underlying #web_url' do
      allow(resource).to receive(:current_url).and_return(subject.current_url)
      expect(wait_for_requests_class).to receive(:wait_for_requests).with({ skip_finished_loading_check: false,
                                                                            skip_resp_code_check: false }).twice

      resource.web_url = subject.current_url
      resource.visit!

      expect(resource).to have_received(:visit).with(subject.current_url)
    end

    it 'calls #visit with the underlying #web_url with skip_resp_code_check specified as true' do
      allow(resource).to receive(:current_url).and_return(subject.current_url)
      expect(wait_for_requests_class).to receive(:wait_for_requests).with({ skip_finished_loading_check: false,
                                                                            skip_resp_code_check: true }).twice

      resource.web_url = subject.current_url
      resource.visit!(skip_resp_code_check: true)

      expect(resource).to have_received(:visit).with(subject.current_url)
    end

    it 'calls #visit with the underlying #web_url with skip_finished_loading_check specified as true' do
      allow(resource).to receive(:current_url).and_return(subject.current_url)
      expect(wait_for_requests_class).to receive(:wait_for_requests).with({ skip_finished_loading_check: true,
                                                                            skip_resp_code_check: false }).twice

      resource.web_url = subject.current_url
      resource.visit!(skip_finished_loading_check: true)

      expect(resource).to have_received(:visit).with(subject.current_url)
    end
  end
end
