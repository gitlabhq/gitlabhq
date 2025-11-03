# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Generator do
  let(:api_classes) { [TestApis::UsersApi] }
  let(:generator) { described_class.new(api_classes: api_classes) }

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
      expect(spec[:paths]).to have_key('/api/v1/users')
    end

    describe 'entity registration and schemas' do
      it 'registers entities from routes' do
        result = generator.generate

        expect(result[:components][:schemas]).to be_present
        expect(result[:components][:schemas]).to be_a(Hash)
      end

      it 'includes registered entity schemas in output' do
        result = generator.generate

        expect(result[:components][:schemas].keys).to include('TestEntitiesUserEntity')
      end

      it 'converts entity schemas to hash format' do
        result = generator.generate
        user_schema = result[:components][:schemas]['TestEntitiesUserEntity']

        expect(user_schema).to be_a(Hash)
        expect(user_schema[:type]).to eq('object')
        expect(user_schema[:properties]).to be_present
      end

      it 'normalizes entity class names' do
        result = generator.generate

        expect(result[:components][:schemas].keys).to all(match(/^[^:]+$/))
      end
    end

    describe 'with explicit entity_classes' do
      subject(:spec) do
        described_class.new(
          api_classes: [TestApis::UsersApi],
          entity_classes: [TestEntities::UserEntity]
        ).generate
      end

      it 'registers explicitly provided entities' do
        expect(spec[:components][:schemas].keys).to include('TestEntitiesUserEntity')
      end

      it 'does not duplicate entities found in routes' do
        schemas = spec[:components][:schemas]

        expect(schemas.keys.count('TestEntitiesUserEntity')).to eq(1)
      end
    end
  end

  describe '#paths' do
    subject(:paths) { generator.paths }

    it 'returns paths hash' do
      expect(paths).to be_a(Hash)
    end

    it 'includes operations from API classes' do
      expect(paths['/api/v1/users'].keys).to contain_exactly('get', 'options', 'post')
    end
  end
end
