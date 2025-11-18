# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Models::Response do
  let(:schema_registry) { Gitlab::GrapeOpenapi::SchemaRegistry.new }
  let(:entity_class) { TestEntities::UserEntity }

  describe '#to_h' do
    it 'returns response with description, content, and schema reference' do
      response = described_class.new(
        status_code: 200,
        description: 'Success',
        entity_class: entity_class
      )

      result = response.to_h(schema_registry)

      expect(result).to eq(
        description: 'Success',
        content: {
          'application/json' => {
            schema: { '$ref': '#/components/schemas/TestEntitiesUserEntity' }
          }
        }
      )
    end

    it 'normalizes nested entity class names' do
      nested_entity = TestEntities::User::PersonEntity
      response = described_class.new(
        status_code: 200,
        description: 'Success',
        entity_class: nested_entity
      )

      result = response.to_h(schema_registry)

      expect(result[:content]['application/json'][:schema]).to eq(
        { '$ref': '#/components/schemas/TestEntitiesUserPersonEntity' }
      )
    end

    it 'supports custom content type' do
      response = described_class.new(
        status_code: 200,
        description: 'Success',
        entity_class: entity_class,
        content_type: 'application/xml'
      )

      result = response.to_h(schema_registry)

      expect(result[:content].keys).to eq(['application/xml'])
    end

    it 'includes headers when provided' do
      headers = {
        'X-Rate-Limit' => { schema: { type: 'integer' }, description: 'Rate limit' },
        'X-Total-Count' => { schema: { type: 'integer' }, description: 'Total items' }
      }

      response = described_class.new(
        status_code: 200,
        description: 'Success',
        entity_class: entity_class,
        headers: headers
      )

      result = response.to_h(schema_registry)

      expect(result[:headers]).to eq(headers)
    end

    it 'omits headers when empty' do
      response = described_class.new(
        status_code: 200,
        description: 'Success',
        entity_class: entity_class
      )

      result = response.to_h(schema_registry)

      expect(result.key?(:headers)).to be false
    end

    it 'converts status_code to string' do
      response = described_class.new(
        status_code: 200,
        description: 'Success',
        entity_class: entity_class
      )

      expect(response.status_code).to eq('200')
    end
  end
end
