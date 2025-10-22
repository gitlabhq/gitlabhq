# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Generator do
  subject(:generator) { described_class.new(api_classes, options) }

  let(:api_classes) { [API::TestAuditEvents] }
  let(:options) { {} }

  before do
    Gitlab::GrapeOpenapi.configure do |config|
      config.info = Gitlab::GrapeOpenapi::Models::Info.new(
        title: 'GitLab REST API',
        description: 'GitLab REST API used to interact with a GitLab installation.',
        version: 'v4',
        terms_of_service: 'https://about.gitlab.com/terms/'
      )

      config.security_schemes = [
        Gitlab::GrapeOpenapi::Models::SecurityScheme.new(
          name: "bearerAuth",
          type: "http",
          scheme: "bearer"
        )
      ]
    end
  end

  describe '#generate' do
    it 'returns the correct keys' do
      expect(generator.generate).to include(:openapi, :info, :servers, :components, :security, :paths)
    end

    it 'returns the correct OpenAPI version' do
      expect(generator.generate[:openapi]).to eq('3.0.0')
    end

    it 'returns the correct security output' do
      expect(generator.generate[:security]).to eq([{ 'http' => [] }])
    end

    it 'executes generate_tags' do
      generator.generate

      expect(generator.tag_registry.tags.size).to eq(5)
    end
  end
end
