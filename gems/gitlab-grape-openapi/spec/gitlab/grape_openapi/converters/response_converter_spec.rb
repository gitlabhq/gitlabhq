# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Converters::ResponseConverter do
  let(:schema_registry) { Gitlab::GrapeOpenapi::SchemaRegistry.new }
  let(:entity_class) { TestEntities::UserEntity }
  let(:route) { instance_double(Grape::Router::Route) }

  before do
    allow(route).to receive(:instance_variable_get).with(:@options).and_return(options)
    allow(route).to receive_messages(options: options, http_codes: http_codes)
  end

  describe '#convert' do
    context 'with entity as Class' do
      let(:options) { { method: 'GET', entity: entity_class } }
      let(:http_codes) { [] }

      it 'returns success response with entity' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert

        expect(result).to eq(
          '200' => {
            description: 'OK',
            content: {
              'application/json' => {
                schema: { '$ref': '#/components/schemas/TestEntitiesUserEntity' }
              }
            }
          }
        )
      end
    end

    context 'with entity as Hash with code and model' do
      let(:options) { { method: 'POST', entity: { code: 201, model: entity_class } } }
      let(:http_codes) { [] }

      it 'returns response with specified code and entity' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert

        expect(result).to eq(
          '201' => {
            description: 'Created',
            content: {
              'application/json' => {
                schema: { '$ref': '#/components/schemas/TestEntitiesUserEntity' }
              }
            }
          }
        )
      end
    end

    context 'with entity as Hash with code only' do
      let(:options) { { method: 'DELETE', entity: { code: 204 } } }
      let(:http_codes) { [] }

      it 'returns response without content' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert

        expect(result).to eq(
          '204' => { description: 'No Content' }
        )
      end
    end

    context 'with entity as Array' do
      let(:options) { { method: 'GET', entity: [{ code: 200 }] } }
      let(:http_codes) { [] }

      it 'returns response without content' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert

        expect(result).to eq(
          '200' => { description: 'OK' }
        )
      end
    end

    context 'with http_codes' do
      let(:options) { { method: 'GET', entity: entity_class } }
      let(:http_codes) do
        [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
      end

      it 'returns success and failure responses' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert

        expect(result.keys).to contain_exactly('200', '400', '401', '404')
        expect(result['200']).to eq(
          description: 'OK',
          content: {
            'application/json' => {
              schema: { '$ref': '#/components/schemas/TestEntitiesUserEntity' }
            }
          }
        )
        expect(result['400']).to eq({ description: 'Bad request' })
        expect(result['401']).to eq({ description: 'Unauthorized' })
        expect(result['404']).to eq({ description: 'Not found' })
      end
    end

    context 'without entity and without http_codes' do
      let(:options) { { method: 'GET' } }
      let(:http_codes) { [] }

      it 'returns default response without content' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert

        expect(result).to eq(
          '200' => { description: 'OK' }
        )
      end
    end

    context 'with POST request without explicit code' do
      let(:options) { { method: 'POST', entity: entity_class } }
      let(:http_codes) { [] }

      it 'infers 201 status code' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert

        expect(result).to eq(
          '201' => {
            description: 'Created',
            content: {
              'application/json' => {
                schema: { '$ref': '#/components/schemas/TestEntitiesUserEntity' }
              }
            }
          }
        )
      end
    end

    context 'with DELETE request without explicit code' do
      let(:options) { { method: 'DELETE', entity: entity_class } }
      let(:http_codes) { [] }

      it 'infers 204 status code' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert

        expect(result).to eq(
          '204' => {
            description: 'No Content',
            content: {
              'application/json' => {
                schema: { '$ref': '#/components/schemas/TestEntitiesUserEntity' }
              }
            }
          }
        )
      end
    end

    context 'with http_codes in Array format' do
      let(:options) { { method: 'GET', entity: entity_class } }
      let(:http_codes) do
        [
          [400, 'Bad Request'],
          [401, 'Unauthorized']
        ]
      end

      it 'handles Array format http_codes' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert

        expect(result['400']).to eq({ description: 'Bad Request' })
        expect(result['401']).to eq({ description: 'Unauthorized' })
      end
    end

    context 'with File as entity (non-Grape::Entity)' do
      let(:options) { { method: 'GET', entity: File } }
      let(:http_codes) { [] }

      it 'returns response without content' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert

        expect(result).to eq(
          '200' => { description: 'OK' }
        )
      end
    end

    context 'with entity as Array of Classes' do
      let(:options) { { method: 'GET', entity: [entity_class] } }
      let(:http_codes) { [] }

      it 'returns response with entity' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert

        expect(result).to eq(
          '200' => {
            description: 'OK',
            content: {
              'application/json' => {
                schema: { '$ref': '#/components/schemas/TestEntitiesUserEntity' }
              }
            }
          }
        )
      end
    end

    context 'with entity as Array with Hash containing model' do
      let(:options) { { method: 'POST', entity: [{ code: 201, model: entity_class }] } }
      let(:http_codes) { [] }

      it 'returns response with specified code and entity' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert

        expect(result).to eq(
          '201' => {
            description: 'Created',
            content: {
              'application/json' => {
                schema: { '$ref': '#/components/schemas/TestEntitiesUserEntity' }
              }
            }
          }
        )
      end
    end

    context 'with entity as mixed Array (Class and Hash)' do
      let(:options) { { method: 'GET', entity: [entity_class, { code: 204, message: 'No content' }] } }
      let(:http_codes) { [] }

      it 'returns responses for both formats' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert

        expect(result.keys).to contain_exactly('200', '204')
        expect(result['200']).to eq(
          description: 'OK',
          content: {
            'application/json' => {
              schema: { '$ref': '#/components/schemas/TestEntitiesUserEntity' }
            }
          }
        )
        expect(result['204']).to eq({ description: 'No content' })
      end
    end
  end
end
