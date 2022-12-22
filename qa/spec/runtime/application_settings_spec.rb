# frozen_string_literal: true

RSpec.describe QA::Runtime::ApplicationSettings do
  let(:api_client) { instance_double(QA::Runtime::API::Client) }
  let(:request) { Struct.new(:url).new('http://api') }
  let(:get_response) { Struct.new(:body).new("{}") }

  describe '.set_application_settings' do
    it 'sets application settings' do
      expect(QA::Runtime::API::Request)
        .to receive(:new)
        .with(api_client, '/application/settings')
        .and_return(request)

      expect(described_class).to receive(:get_application_settings)

      expect(described_class)
        .to receive(:put)
        .with(request.url, { allow_local_requests_from_web_hooks_and_services: true })
        .and_return(Struct.new(:code).new(200))

      described_class.set_application_settings(
        api_client: api_client,
        allow_local_requests_from_web_hooks_and_services: true
      )
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

      described_class.get_application_settings(api_client: api_client)
    end
  end
end
