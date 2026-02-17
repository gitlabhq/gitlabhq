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

      config.excluded_api_classes = ['TestApis::ExcludedApi']
    end
  end

  describe '#initialize' do
    context 'when excluded_api_classes contains invalid values' do
      [
        [true, 'boolean true'],
        [false, 'boolean false'],
        [123, 'integer'],
        [45.67, 'float'],
        [nil, 'nil'],
        [:symbol_value, 'symbol'],
        [{ key: 'value' }, 'hash'],
        [%w[nested array], 'array'],
        ['NonExistent::ApiClass', 'non-existent class name'],
        ['', 'empty string'],
        [[], 'empty array']
      ].each do |invalid_value, description|
        context "with #{description}" do
          before do
            Gitlab::GrapeOpenapi.configuration.excluded_api_classes = [invalid_value]
          end

          it 'does not filter out any valid api classes' do
            expect(generator.instance_variable_get(:@api_classes)).to eq(api_classes)
          end
        end
      end
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

    context 'when excluded_api_classes contains valid values' do
      let(:api_classes) { [TestApis::UsersApi, TestApis::ExcludedApi] }

      it 'removes excluded api classes' do
        expect(generator.generate[:paths].keys).not_to include("/api/v1/internal")
      end
    end

    describe 'tags sorting' do
      let(:tag_names) { spec[:tags].map { |t| t[:name] } }

      context 'with a single API class' do
        let(:api_classes) { [TestApis::UsersApi] }

        it 'returns tags sorted by name' do
          expect(tag_names).to eq(tag_names.sort)
        end
      end

      context 'with multiple API classes' do
        let(:api_classes) { [TestApis::NestedApi, TestApis::UsersApi] }

        it 'sorts tags alphabetically across all API classes' do
          expect(tag_names).to eq(tag_names.sort)
        end

        it 'maintains alphabetical order regardless of API class order' do
          reversed_generator = described_class.new(api_classes: api_classes.reverse)
          reversed_spec = reversed_generator.generate

          expect(spec[:tags]).to eq(reversed_spec[:tags])
        end
      end

      context 'with no API classes' do
        let(:api_classes) { [] }

        it 'returns an empty array' do
          expect(spec[:tags]).to eq([])
        end
      end

      context 'with tags containing special characters' do
        let(:api_classes) { [TestApis::SpecialTagsApi] }

        it 'sorts tags with unusual formats (numbers, hyphens, underscores, camel case) correctly' do
          expect(tag_names).to eq(tag_names.sort)
          # Tag names get normalized by `Tag.normalize_tag_names`: e.g. "_user_management" becomes " User Management"
          expect(tag_names).to include("123numeric", "-api-v2", " user management", "Adminpanel")
        end
      end

      context 'with a tag without name' do
        before do
          # Manually inject a malformed tag to test defensive sorting
          generator.tag_registry.tags << { description: 'Tag without name' }
        end

        it 'handles tags without name gracefully during sorting' do
          expect { spec }.not_to raise_error
        end

        it 'treats missing name as empty string for sorting' do
          expect(tag_names).to include(nil)
          expect(spec[:tags]).to be_an(Array)
        end
      end
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
