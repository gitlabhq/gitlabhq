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

    it 'overwrites schemas that have already been registered' do
      schema_registry.register(entity_class, schema_model)
      schema_registry.register(entity_class, schema_model)
      expect(schema_registry.schemas['TestEntitiesUserPersonEntity']).to eq(schema_model)
      expect(schema_registry.schemas.count).to eq(1)
    end

    it 'normalizes class names' do
      schema_registry.register(entity_class, schema_model)
      expect(schema_registry.schemas["TestEntitiesUserPersonEntity"]).to eq(schema_model)
    end
  end
end
