# frozen_string_literal: true

describe QA::Runtime::ApplicationSettings do
  let(:api_client) { double('QA::Runtime::API::Client') }
  let(:request) { Struct.new(:url).new('http://api') }
  let(:get_response) { Struct.new(:body).new("{}") }

  before do
    allow(described_class).to receive(:api_client).and_return(api_client)
  end

  describe '.set_application_settings' do
    it 'sets application settings' do
      expect(QA::Runtime::API::Request)
        .to receive(:new)
        .with(api_client, '/application/settings')
        .and_return(request)

      expect(described_class)
        .to receive(:put)
        .with(request.url, { allow_local_requests_from_web_hooks_and_services: true })
        .and_return(Struct.new(:code).new(200))

      subject.set_application_settings(allow_local_requests_from_web_hooks_and_services: true)
    end
  end

  describe '.get_application_settings' do
    it 'gets application settings' do
      expect(QA::Runtime::API::Request)
        .to receive(:new)
        .with(api_client, '/application/settings')
        .and_return(request)

      expect(described_class)
        .to receive(:get)
        .with(request.url)
        .and_return(get_response)

      subject.get_application_settings
    end
  end
end
