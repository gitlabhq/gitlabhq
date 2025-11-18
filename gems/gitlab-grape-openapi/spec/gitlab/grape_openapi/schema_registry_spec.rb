# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::SchemaRegistry do
  let(:schema_registry) { described_class.new }

  describe '#register' do
    let(:entity_class) { TestEntities::User::PersonEntity }
    let(:schema_model) { Gitlab::GrapeOpenapi::Models::Schema.new }

    it 'does not register if the schema is not a Gitlab::GrapeOpenapi::Models::Schema' do
      schema_registry.register(entity_class, 'not a schema')

      expect(schema_registry.schemas).to be_empty
    end

    it 'skips registration if entity already registered (deduplication)' do
      first_schema = Gitlab::GrapeOpenapi::Models::Schema.new
      second_schema = Gitlab::GrapeOpenapi::Models::Schema.new

      schema_registry.register(entity_class, first_schema)
      schema_registry.register(entity_class, second_schema)

      expect(schema_registry.schemas.count).to eq(1)
      expect(schema_registry.schemas['TestEntitiesUserPersonEntity']).to eq(first_schema)
      expect(schema_registry.schemas['TestEntitiesUserPersonEntity']).not_to eq(second_schema)
    end

    it 'returns normalized name when skipping duplicate' do
      schema_registry.register(entity_class, schema_model)
      result = schema_registry.register(entity_class, schema_model)

      expect(result).to eq('TestEntitiesUserPersonEntity')
    end

    it 'normalizes class names' do
      schema_registry.register(entity_class, schema_model)

      expect(schema_registry.schemas["TestEntitiesUserPersonEntity"]).to eq(schema_model)
    end
  end

  describe '#normalize_entity_class' do
    it 'removes colons from entity class name' do
      entity_class = TestEntities::User::PersonEntity

      expect(schema_registry.normalize_entity_class(entity_class)).to eq('TestEntitiesUserPersonEntity')
    end
  end
end
