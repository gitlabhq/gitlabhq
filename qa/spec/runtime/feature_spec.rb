# frozen_string_literal: true

describe QA::Runtime::Feature do
  let(:api_client) { double('QA::Runtime::API::Client') }
  let(:request) { Struct.new(:url).new('http://api') }
  let(:response) { Struct.new(:code).new(201) }

  before do
    allow(described_class).to receive(:api_client).and_return(api_client)
  end

  describe '.enable' do
    it 'enables a feature flag' do
      expect(QA::Runtime::API::Request)
        .to receive(:new)
        .with(api_client, "/features/a-flag")
        .and_return(request)
      expect(described_class)
        .to receive(:post)
        .with(request.url, { value: true })
        .and_return(response)

      subject.enable('a-flag')
    end
  end

  describe '.disable' do
    it 'disables a feature flag' do
      expect(QA::Runtime::API::Request)
        .to receive(:new)
        .with(api_client, "/features/a-flag")
        .and_return(request)
      expect(described_class)
        .to receive(:post)
        .with(request.url, { value: false })
        .and_return(response)

      subject.disable('a-flag')
    end
  end
end
