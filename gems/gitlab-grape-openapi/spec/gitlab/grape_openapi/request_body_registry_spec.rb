# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::RequestBodyRegistry do
  subject(:registry) { described_class.new }

  describe '#register' do
    context 'with a valid schema' do
      let(:schema) do
        {
          type: 'object',
          properties: {
            'name' => { type: 'string', description: 'User name' },
            'email' => { type: 'string', description: 'User email' }
          },
          required: ['name']
        }
      end

      it 'returns a $ref reference' do
        result = registry.register(schema)
        expect(result).to have_key('$ref')
        expect(result['$ref']).to start_with('#/components/schemas/')
      end

      it 'registers the schema' do
        registry.register(schema)
        expect(registry.schemas).not_to be_empty
      end

      it 'stores the original schema' do
        registry.register(schema)
        schema_name = registry.schemas.each_key.first
        expect(registry.schemas[schema_name]).to eq(schema)
      end

      it 'uses hash-based naming' do
        registry.register(schema)
        schema_name = registry.schemas.each_key.first
        expect(schema_name).to match(/^RequestBody_[a-f0-9]{12}$/)
      end
    end

    context 'with duplicate schemas' do
      let(:schema1) do
        {
          type: 'object',
          properties: {
            'name' => { type: 'string' }
          }
        }
      end

      let(:schema2) do
        {
          type: 'object',
          properties: {
            'name' => { type: 'string' }
          }
        }
      end

      it 'returns the same $ref for identical schemas' do
        ref1 = registry.register(schema1)
        ref2 = registry.register(schema2)
        expect(ref1).to eq(ref2)
      end

      it 'only stores one schema' do
        registry.register(schema1)
        registry.register(schema2)
        expect(registry.schemas.size).to eq(1)
      end
    end

    context 'with different schemas' do
      let(:schema1) do
        {
          type: 'object',
          properties: {
            'name' => { type: 'string' }
          }
        }
      end

      let(:schema2) do
        {
          type: 'object',
          properties: {
            'email' => { type: 'string' }
          }
        }
      end

      it 'returns different $refs' do
        ref1 = registry.register(schema1)
        ref2 = registry.register(schema2)
        expect(ref1).not_to eq(ref2)
      end

      it 'stores both schemas' do
        registry.register(schema1)
        registry.register(schema2)
        expect(registry.schemas.size).to eq(2)
      end

      it 'generates unique hash-based names' do
        registry.register(schema1)
        registry.register(schema2)
        names = registry.schemas.keys
        expect(names).to all(match(/^RequestBody_[a-f0-9]{12}$/))
        expect(names.uniq.size).to eq(2)
      end
    end

    context 'with nil schema' do
      it 'returns nil' do
        expect(registry.register(nil)).to be_nil
      end

      it 'does not register anything' do
        registry.register(nil)
        expect(registry.schemas).to be_empty
      end
    end

    context 'with empty schema' do
      it 'returns nil' do
        expect(registry.register({})).to be_nil
      end

      it 'does not register anything' do
        registry.register({})
        expect(registry.schemas).to be_empty
      end
    end

    context 'with schema key ordering' do
      let(:schema1) do
        {
          type: 'object',
          properties: { 'a' => { type: 'string' } }
        }
      end

      let(:schema2) do
        {
          properties: { 'a' => { type: 'string' } },
          type: 'object'
        }
      end

      it 'treats schemas with different key order as identical' do
        ref1 = registry.register(schema1)
        ref2 = registry.register(schema2)
        expect(ref1).to eq(ref2)
      end

      it 'only stores one schema' do
        registry.register(schema1)
        registry.register(schema2)
        expect(registry.schemas.size).to eq(1)
      end
    end
  end

  describe '#schemas' do
    it 'returns empty hash initially' do
      expect(registry.schemas).to eq({})
    end

    it 'returns registered schemas' do
      schema = { type: 'object', properties: { 'id' => { type: 'integer' } } }
      registry.register(schema)
      expect(registry.schemas.values).to include(schema)
    end
  end
end
