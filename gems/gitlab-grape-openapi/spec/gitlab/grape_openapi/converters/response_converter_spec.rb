# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Converters::ResponseConverter do
  let(:schema_registry) { Gitlab::GrapeOpenapi::SchemaRegistry.new }
  let(:entity_class) { TestEntities::UserEntity }
  let(:route) { instance_double(Grape::Router::Route) }

  before do
    allow(route).to receive_messages(
      options: options,
      http_codes: http_codes,
      path: '/api/:version/resource(.:format)'
    )
  end

  describe '#convert' do
    context 'with entity as Class' do
      let(:options) { { method: 'GET', entity: entity_class } }
      let(:http_codes) { [] }

      it 'returns success response with entity' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert
        success_results = result.select { |k, _| k.to_i.between?(200, 299) }
        expect(success_results).to eq(
          { '200' => {
            content: {
              'application/json' => {
                schema: { '$ref' => '#/components/schemas/TestEntitiesUserEntity' }
              }
            },
            description: 'OK'
          } }
        )
      end
    end

    context 'when only :success is set (declared via the success DSL)' do
      let(:http_codes) { [] }

      shared_examples 'emits the entity ref in the success response' do
        it 'falls back to :success and emits the entity $ref' do
          converter = described_class.new(route, schema_registry)
          result = converter.convert

          success_results = result.select { |k, _| k.to_i.between?(200, 299) }
          expect(success_results.each_value.first[:content]['application/json'][:schema]).to eq(
            { '$ref' => '#/components/schemas/TestEntitiesUserEntity' }
          )
        end
      end

      context 'with Class shape' do
        let(:options) { { method: 'GET', success: entity_class } }

        include_examples 'emits the entity ref in the success response'
      end

      context 'with Hash shape' do
        let(:options) { { method: 'POST', success: { code: 201, model: entity_class } } }

        include_examples 'emits the entity ref in the success response'
      end

      context 'with Array shape' do
        let(:options) { { method: 'POST', success: [{ code: 201, model: entity_class, message: 'Created' }] } }

        include_examples 'emits the entity ref in the success response'
      end
    end

    context 'when http_codes includes a success code that overlaps with the entity response' do
      let(:options) { { method: 'POST', entity: entity_class } }
      let(:http_codes) { [[201, 'Created via runner']] }

      it 'preserves the entity ref on the success response and updates only the description' do
        result = described_class.new(route, schema_registry).convert

        expect(result['201']).to eq(
          description: 'Created via runner',
          content: {
            'application/json' => {
              schema: { '$ref' => '#/components/schemas/TestEntitiesUserEntity' }
            }
          }
        )
      end
    end

    context 'when both :entity and :success are set' do
      let(:options) do
        { method: 'GET', entity: entity_class, success: TestEntities::User::PersonEntity }
      end

      let(:http_codes) { [] }

      it 'prefers :entity (preserving existing precedence)' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert

        success_results = result.select { |k, _| k.to_i.between?(200, 299) }
        expect(success_results.each_value.first[:content]['application/json'][:schema]).to eq(
          { '$ref' => '#/components/schemas/TestEntitiesUserEntity' }
        )
      end
    end

    context 'with entity as Hash with code and model' do
      let(:options) { { method: 'POST', entity: { code: 201, model: entity_class } } }
      let(:http_codes) { [] }

      it 'returns response with specified code and entity' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert
        success_results = result.select { |k, _| k.to_i.between?(200, 299) }

        expect(success_results).to eq(
          { '201' => {
            content: {
              'application/json' => {
                schema: { '$ref' => '#/components/schemas/TestEntitiesUserEntity' }
              }
            },
            description: 'Created'
          } }
        )
      end

      context 'with example' do
        let(:options) do
          { method: 'GET', entity: { code: 200, model: entity_class, example: { id: 1, name: 'Jane' } } }
        end

        it 'includes example in the response content' do
          result = described_class.new(route, schema_registry).convert

          expect(result['200'][:content]['application/json'][:example]).to eq({ id: 1, name: 'Jane' })
        end
      end

      context 'with examples' do
        let(:options) do
          {
            method: 'GET',
            entity: {
              code: 200,
              model: entity_class,
              examples: {
                'NewUser' => { summary: 'A new user', value: { id: 1, name: 'Jane' } },
                'AdminUser' => { summary: 'An admin user', value: { id: 2, name: 'Bob', admin: true } }
              }
            }
          }
        end

        it 'includes examples in the response content' do
          result = described_class.new(route, schema_registry).convert

          expect(result['200'][:content]['application/json'][:examples]).to eq(
            'NewUser' => { summary: 'A new user', value: { id: 1, name: 'Jane' } },
            'AdminUser' => { summary: 'An admin user', value: { id: 2, name: 'Bob', admin: true } }
          )
        end
      end
    end

    context 'with entity as Hash with code only' do
      let(:options) { { method: 'DELETE', entity: { code: 204 } } }
      let(:http_codes) { [] }

      it 'returns response without content' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert
        success_results = result.select { |k, _| k.to_i.between?(200, 299) }

        expect(success_results).to eq(
          { '204' => { description: 'No Content' } }
        )
      end
    end

    context 'with entity as Array' do
      let(:options) { { method: 'GET', entity: [{ code: 200 }] } }
      let(:http_codes) { [] }

      it 'returns response without content' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert
        success_results = result.select { |k, _| k.to_i.between?(200, 299) }

        expect(success_results).to eq(
          { '200' => { description: 'OK' } }
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

        expect(result).to eq(
          '200' => {
            description: 'OK',
            content: {
              'application/json' => {
                schema: { '$ref' => '#/components/schemas/TestEntitiesUserEntity' }
              }
            }
          },
          '400' => { description: 'Bad request' },
          '401' => { description: 'Unauthorized' },
          '404' => { description: 'Not found' }
        )
      end
    end

    context 'with GET request without entity and without http_codes' do
      let(:options) { { method: 'GET' } }
      let(:http_codes) { [] }

      it 'infers 200 response without content' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert
        success_results = result.select { |k, _| k.to_i.between?(200, 299) }

        expect(success_results).to eq(
          { '200' => { description: 'OK' } }
        )
      end
    end

    context 'with POST request without explicit code' do
      let(:options) { { method: 'POST', entity: entity_class } }
      let(:http_codes) { [] }

      it 'infers 201 status code' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert
        success_results = result.select { |k, _| k.to_i.between?(200, 299) }

        expect(success_results).to eq(
          { '201' => {
            content: {
              'application/json' => {
                schema: { '$ref' => '#/components/schemas/TestEntitiesUserEntity' }
              }
            },
            description: 'Created'
          } }
        )
      end
    end

    context 'with DELETE request without explicit code' do
      let(:options) { { method: 'DELETE', entity: entity_class } }
      let(:http_codes) { [] }

      it 'infers 204 status code' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert
        success_results = result.select { |k, _| k.to_i.between?(200, 299) }

        expect(success_results).to eq(
          { '204' => {
            content: {
              'application/json' => {
                schema: { '$ref' => '#/components/schemas/TestEntitiesUserEntity' }
              }
            },
            description: 'No Content'
          } }
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

    context 'when GET request and File as entity (non-Grape::Entity)' do
      let(:options) { { method: 'GET', entity: File } }
      let(:http_codes) { [] }

      it 'infers 200 response without content' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert
        success_results = result.select { |k, _| k.to_i.between?(200, 299) }

        expect(success_results).to eq(
          { '200' => { description: 'OK' } }
        )
      end
    end

    context 'when GET request with entity as Array of Classes' do
      let(:options) { { method: 'GET', entity: [entity_class] } }
      let(:http_codes) { [] }

      it 'infers 200 response with entity' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert
        success_results = result.select { |k, _| k.to_i.between?(200, 299) }

        expect(success_results).to eq(
          { '200' => {
            content: {
              'application/json' => {
                schema: { '$ref' => '#/components/schemas/TestEntitiesUserEntity' }
              }
            },
            description: 'OK'
          } }
        )
      end
    end

    context 'when POST request with entity as Array with Hash containing model' do
      let(:options) { { method: 'POST', entity: [{ code: 201, model: entity_class }] } }
      let(:http_codes) { [] }

      it 'infers 201 response with specified code and entity' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert
        success_results = result.select { |k, _| k.to_i.between?(200, 299) }

        expect(success_results).to eq(
          { '201' => {
            content: {
              'application/json' => {
                schema: { '$ref' => '#/components/schemas/TestEntitiesUserEntity' }
              }
            },
            description: 'Created'
          } }
        )
      end

      context 'with example' do
        let(:options) do
          { method: 'POST', entity: [{ code: 201, model: entity_class, example: { id: 1, name: 'Jane' } }] }
        end

        it 'includes example in the response content' do
          result = described_class.new(route, schema_registry).convert

          expect(result['201'][:content]['application/json'][:example]).to eq({ id: 1, name: 'Jane' })
        end
      end

      context 'with examples' do
        let(:options) do
          {
            method: 'POST',
            entity: [{
              code: 201,
              model: entity_class,
              examples: {
                'NewUser' => { summary: 'A new user', value: { id: 1, name: 'Jane' } },
                'AdminUser' => { summary: 'An admin user', value: { id: 2, name: 'Bob', admin: true } }
              }
            }]
          }
        end

        it 'includes examples in the response content' do
          result = described_class.new(route, schema_registry).convert

          expect(result['201'][:content]['application/json'][:examples]).to eq(
            'NewUser' => { summary: 'A new user', value: { id: 1, name: 'Jane' } },
            'AdminUser' => { summary: 'An admin user', value: { id: 2, name: 'Bob', admin: true } }
          )
        end
      end
    end

    context 'with entity as mixed Array (Class and Hash)' do
      let(:options) { { method: 'GET', entity: [entity_class, { code: 204, message: 'No content' }] } }
      let(:http_codes) { [] }

      it 'returns responses for both formats' do
        converter = described_class.new(route, schema_registry)
        result = converter.convert
        success_results = result.select { |k, _| k.to_i.between?(200, 299) }

        expect(success_results).to eq(
          { '200' => {
              content: {
                'application/json' => {
                  schema: { '$ref' => '#/components/schemas/TestEntitiesUserEntity' }
                }
              }, description: 'OK'
            },
            '204' => { description: 'No content' } }
        )
      end
    end

    describe 'failure response inference' do
      context 'with GET request' do
        let(:options) { { method: 'GET', entity: entity_class } }
        let(:http_codes) { [] }

        context 'with no params and no resource path parameters' do
          it 'does not infer any failure codes' do
            result = described_class.new(route, schema_registry).convert
            expect(result.keys.select { |k| k.to_i.between?(400, 499) }).to be_empty
          end
        end

        context 'with declared params and no resource path parameters' do
          before do
            allow(route).to receive(:options).and_return(options.merge(params: { id: { required: true } }))
          end

          it 'infers 400 only' do
            result = described_class.new(route, schema_registry).convert
            expect(result.keys.select { |k| k.to_i.between?(400, 499) }).to contain_exactly('400')
          end
        end

        context 'with resource path parameters and no declared params' do
          before do
            allow(route).to receive(:path).and_return('/api/:version/resource/:id(.:format)')
          end

          it 'infers 404 only' do
            result = described_class.new(route, schema_registry).convert
            expect(result.keys.select { |k| k.to_i.between?(400, 499) }).to contain_exactly('404')
          end
        end

        context 'with both declared params and resource path parameters' do
          before do
            allow(route).to receive_messages(
              options: options.merge(params: { id: { required: true } }),
              path: '/api/:version/resource/:id(.:format)'
            )
          end

          it 'infers 400 and 404' do
            result = described_class.new(route, schema_registry).convert
            expect(result['400']).to eq({ description: 'Bad Request' })
            expect(result['404']).to eq({ description: 'Not Found' })
          end
        end
      end

      context 'with POST request' do
        let(:options) { { method: 'POST', entity: entity_class } }
        let(:http_codes) { [] }

        context 'with no declared params and no resource path parameters' do
          it 'infers 400 from HTTP method alone' do
            result = described_class.new(route, schema_registry).convert
            expect(result.keys.select { |k| k.to_i.between?(400, 499) }).to contain_exactly('400')
          end
        end
      end

      context 'when http_codes is explicitly provided' do
        let(:options) { { method: 'POST', entity: entity_class } }
        let(:http_codes) { [{ code: 422, message: 'Unprocessable' }] }

        it 'uses explicit codes and does not infer' do
          result = described_class.new(route, schema_registry).convert
          expect(result.keys.select { |k| k.to_i.between?(400, 499) }).to contain_exactly('422')
        end
      end
    end
  end
end
