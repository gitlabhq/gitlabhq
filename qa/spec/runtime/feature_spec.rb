# frozen_string_literal: true

describe QA::Runtime::Feature do
  let(:api_client) { double('QA::Runtime::API::Client') }
  let(:request) { Struct.new(:url).new('http://api') }
  let(:response_post) { Struct.new(:code).new(201) }
  let(:response_get) { Struct.new(:code, :body).new(200, '[{ "name": "a-flag", "state": "on" }]') }

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
        .and_return(response_post)

      subject.enable('a-flag')
    end
  end

  describe '.enable_and_verify' do
    it 'enables a feature flag' do
      allow(described_class).to receive(:get).and_return(response_get)

      expect(QA::Runtime::API::Request).to receive(:new)
        .with(api_client, "/features/a-flag").and_return(request)
      expect(described_class).to receive(:post)
        .with(request.url, { value: true }).and_return(response_post)
      expect(QA::Runtime::API::Request).to receive(:new)
        .with(api_client, "/features").and_return(request)

      subject.enable_and_verify('a-flag')
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
        .and_return(response_post)

      subject.disable('a-flag')
    end
  end

  describe '.disable_and_verify' do
    it 'disables a feature flag' do
      allow(described_class).to receive(:get)
        .and_return(Struct.new(:code, :body).new(200, '[{ "name": "a-flag", "state": "off" }]'))

      expect(QA::Runtime::API::Request).to receive(:new)
        .with(api_client, "/features/a-flag").and_return(request)
      expect(described_class).to receive(:post)
        .with(request.url, { value: false }).and_return(response_post)
      expect(QA::Runtime::API::Request).to receive(:new)
        .with(api_client, "/features").and_return(request)

      subject.disable_and_verify('a-flag')
    end
  end

  describe '.enabled?' do
    it 'returns a feature flag state' do
      expect(QA::Runtime::API::Request)
        .to receive(:new)
        .with(api_client, "/features")
        .and_return(request)
      expect(described_class)
        .to receive(:get)
        .and_return(response_get)

      expect(subject.enabled?('a-flag')).to be_truthy
    end
  end
end
