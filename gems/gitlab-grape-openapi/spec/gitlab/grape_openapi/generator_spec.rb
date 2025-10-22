# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeOpenapi::Generator do
  let(:api_prefix) { '/api' }
  let(:api_version) { 'v1' }
  let(:base_path) { "#{api_prefix}/#{api_version}" }
  let(:api_classes) { [TestApis::UsersApi] }
  let(:generator) { described_class.new(api_classes) }

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
    subject(:spec) { generator.generate }

    it 'returns the correct keys' do
      expect(generator.generate).to include(:openapi, :info, :servers, :components, :security, :paths)
    end

    it 'returns the correct OpenAPI version' do
      expect(generator.generate[:openapi]).to eq('3.0.0')
    end

    it 'returns the correct security output' do
      expect(generator.generate[:security]).to eq([{ 'http' => [] }])
    end

    it 'includes paths from API classes' do
      expect(spec[:paths]).to have_key("#{base_path}/users")
    end
  end

  describe '#paths' do
    subject(:paths) { generator.paths }

    it 'returns paths hash' do
      expect(paths).to be_a(Hash)
    end

    it 'includes operations from API classes' do
      expect(paths["#{base_path}/users"].keys).to contain_exactly('get', 'options', 'post')
    end
  end
end
