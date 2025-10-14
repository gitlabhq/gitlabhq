# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Models::Schema do
  let!(:registry) { Gitlab::GrapeOpenapi::SchemaRegistry.new }
  let!(:converter) { Gitlab::GrapeOpenapi::Converters::EntityConverter.new(TestEntities::UserEntity, registry).convert }

  subject(:schema) { registry.schemas["TestEntitiesUserEntity"] }

  describe '#initialize' do
    it 'has the correct properties' do
      expect(schema.properties.keys).to contain_exactly(:created_at, :email, :id, :name, :updated_at)
    end
  end

  describe '#to_h' do
    it 'has the correct type' do
      expect(schema.to_h[:type]).to eq('object')
    end
  end
end
