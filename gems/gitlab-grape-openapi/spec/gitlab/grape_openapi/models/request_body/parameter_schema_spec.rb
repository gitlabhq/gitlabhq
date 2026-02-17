# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles
RSpec.describe Gitlab::GrapeOpenapi::Models::RequestBody::ParameterSchema do
  subject(:parameter_schema) do
    described_class.new(route: route)
  end

  let(:route) do
    double('Route',
      path: route_path,
      app: double('App',
        inheritable_setting: double('InheritableSetting',
          namespace_stackable: double('NamespaceStackable',
            new_values: { validations: validations }
          )
        )
      )
    )
  end

  let(:route_path) { "/api/v1/users/:id" }
  let(:validations) { [] }

  describe '#build' do
    subject(:method_call) do
      parameter_schema.build(key, param_options)
    end

    describe 'when type starts with "[" and has no comma (e.g., [String])' do
      let(:key) { :items }

      context 'with [String] notation' do
        let(:param_options) { { type: '[String]', desc: 'Milestone titles', required: false } }

        it 'generates complete array schema' do
          expect(method_call).to eq(
            type: 'array',
            items: { type: 'string' },
            description: 'Milestone titles'
          )
        end
      end

      context 'with [Integer] notation' do
        let(:param_options) { { type: '[Integer]', desc: 'IDs', required: true } }

        it 'generates complete array schema with integer items' do
          expect(method_call).to eq(
            type: 'array',
            items: { type: 'integer' },
            description: 'IDs'
          )
        end
      end

      context 'without description' do
        let(:param_options) { { type: '[String]', required: true } }

        it 'generates array schema without description' do
          expect(method_call).to eq(
            type: 'array',
            items: { type: 'string' }
          )
        end
      end
    end

    describe 'when type starts with "[" and has comma (e.g., [String, Integer])' do
      let(:key) { :value }

      context 'with two types' do
        let(:param_options) { { type: '[String, Integer]', desc: 'Value can be string or integer', required: true } }

        it 'generates complete oneOf schema' do
          expect(method_call).to eq(
            oneOf: [
              { type: 'string' },
              { type: 'integer' }
            ]
          )
        end
      end
    end

    describe 'when type is a file' do
      let(:key) { :file }

      context 'with only workhorse uploads' do
        let(:param_options) do
          {
            type: 'API::Validations::Types::WorkhorseFile',
            desc: 'User profile picture',
            required: false
          }
        end

        it 'returns the expected parameter schema' do
          expect(method_call).to eq(
            {
              type: 'string',
              format: 'binary',
              description: 'User profile picture'
            }
          )
        end
      end

      context 'with multiple file upload options' do
        let(:param_options) do
          {
            type: %w[API::Validations::Types::WorkhorseFile Rack::Multipart::UploadedFile],
            desc: 'User profile picture',
            required: false
          }
        end

        it 'returns the expected parameter schema' do
          expect(method_call).to eq(
            {
              type: 'string',
              format: 'binary',
              description: 'User profile picture'
            }
          )
        end
      end
    end

    describe 'when values is a Range' do
      let(:key) { :position }

      context 'with integer range' do
        let(:param_options) { { type: 'Integer', desc: 'Position', required: true, values: (1..20) } }

        it 'generates complete range schema' do
          expect(method_call).to eq(
            type: 'integer',
            minimum: 1,
            maximum: 20,
            description: 'Position'
          )
        end
      end

      context 'without description' do
        let(:param_options) { { type: 'Integer', required: true, values: (5..10) } }

        it 'generates range schema without description' do
          expect(method_call).to eq(
            type: 'integer',
            minimum: 5,
            maximum: 10
          )
        end
      end
    end

    describe 'when values is present (enum)' do
      let(:key) { :status }

      context 'with string enum values' do
        let(:param_options) do
          { type: 'String', desc: 'User status', required: true, values: %w[active inactive pending] }
        end

        it 'generates complete enum schema' do
          expect(method_call).to eq(
            type: 'string',
            enum: %w[active inactive pending],
            description: 'User status'
          )
        end
      end

      context 'without description' do
        let(:param_options) { { type: 'String', required: true, values: %w[yes no] } }

        it 'generates enum schema without description' do
          expect(method_call).to eq(
            type: 'string',
            enum: %w[yes no]
          )
        end
      end

      context 'with Proc enum values' do
        let(:param_options) { { type: 'String', desc: 'Dynamic values', required: true, values: -> { %w[a b c] } } }

        it 'generates schema without enum when values is a Proc' do
          expect(method_call).to eq(
            type: 'string',
            description: 'Dynamic values'
          )
        end
      end

      context 'with lambda enum values' do
        let(:param_options) { { type: 'Integer', required: true, values: -> { [1, 2, 3] } } }

        it 'generates schema without enum when values is a lambda' do
          expect(method_call).to eq(
            type: 'integer'
          )
        end
      end
    end

    describe 'when type is Array with nested params' do
      let(:key) { :items }

      context 'with nested object params' do
        let(:param_options) do
          {
            type: 'Array',
            desc: 'List of items',
            required: true,
            params: {
              name: { type: 'String', desc: 'Item name', required: true },
              quantity: { type: 'Integer', desc: 'Quantity', required: true },
              notes: { type: 'String', desc: 'Optional notes', required: false }
            }
          }
        end

        it 'generates complete nested array schema' do
          expect(method_call).to eq(
            type: 'array',
            description: 'List of items',
            items: {
              type: 'object',
              properties: {
                'name' => { type: 'string', description: 'Item name' },
                'quantity' => { type: 'integer', description: 'Quantity' },
                'notes' => { type: 'string', description: 'Optional notes' }
              },
              required: %w[name quantity]
            }
          )
        end
      end

      context 'with empty params' do
        let(:param_options) { { type: 'Array', desc: 'Empty array', required: false, params: {} } }

        it 'generates array schema with default object items' do
          expect(method_call).to eq(
            type: 'array',
            description: 'Empty array',
            items: { type: 'object' }
          )
        end
      end

      context 'with no required nested params' do
        let(:param_options) do
          {
            type: 'Array',
            desc: 'Optional fields',
            required: false,
            params: {
              label: { type: 'String', desc: 'Label', required: false }
            }
          }
        end

        it 'generates nested array schema without required array' do
          expect(method_call).to eq(
            type: 'array',
            description: 'Optional fields',
            items: {
              type: 'object',
              properties: {
                'label' => { type: 'string', description: 'Label' }
              }
            }
          )
        end
      end
    end

    describe 'when resolved type includes "[" (e.g., Array[String])' do
      let(:key) { :tags }

      context 'with Array[String] notation' do
        let(:param_options) { { type: 'Array[String]', desc: 'User tags', required: true } }

        it 'generates complete array schema' do
          expect(method_call).to eq(
            type: 'array',
            items: { type: 'arraystring' },
            description: 'User tags'
          )
        end
      end

      context 'without description' do
        let(:param_options) { { type: 'Array[Integer]', required: true } }

        it 'generates array schema without description' do
          expect(method_call).to eq(
            type: 'array',
            items: { type: 'arrayinteger' }
          )
        end
      end
    end

    describe 'when type is Hash with nested params' do
      let(:key) { :metadata }

      context 'with simple nested params' do
        let(:param_options) do
          {
            type: 'Hash',
            desc: 'Metadata object',
            required: true,
            params: {
              title: { type: 'String', desc: 'Title', required: true },
              description: { type: 'String', desc: 'Description', required: false },
              version: { type: 'Integer', desc: 'Version number', required: true }
            }
          }
        end

        it 'generates complete nested hash schema' do
          expect(method_call).to eq(
            type: 'object',
            description: 'Metadata object',
            properties: {
              'title' => { type: 'string', description: 'Title' },
              'description' => { type: 'string', description: 'Description' },
              'version' => { type: 'integer', description: 'Version number' }
            },
            required: %w[title version]
          )
        end
      end

      context 'with empty params' do
        let(:param_options) { { type: 'Hash', desc: 'Empty hash', required: false, params: {} } }

        it 'generates object schema without properties' do
          expect(method_call).to eq(
            type: 'object',
            description: 'Empty hash'
          )
        end
      end

      context 'with deeply nested structures' do
        let(:key) { :config }
        let(:param_options) do
          {
            type: 'Hash',
            desc: 'Configuration object',
            required: true,
            params: {
              database: {
                type: 'Hash',
                desc: 'Database configuration',
                required: true,
                params: {
                  host: { type: 'String', desc: 'Database host', required: true },
                  port: { type: 'Integer', desc: 'Database port', required: false, default: 5432 },
                  credentials: {
                    type: 'Hash',
                    desc: 'Database credentials',
                    required: true,
                    params: {
                      username: { type: 'String', desc: 'Username', required: true },
                      password: { type: 'String', desc: 'Password', required: true }
                    }
                  }
                }
              }
            }
          }
        end

        it 'generates complete multi-level nested schema' do
          expect(method_call).to eq(
            type: 'object',
            description: 'Configuration object',
            properties: {
              'database' => {
                type: 'object',
                description: 'Database configuration',
                properties: {
                  'host' => { type: 'string', description: 'Database host' },
                  'port' => { type: 'integer', description: 'Database port', default: 5432 },
                  'credentials' => {
                    type: 'object',
                    description: 'Database credentials',
                    properties: {
                      'username' => { type: 'string', description: 'Username' },
                      'password' => { type: 'string', description: 'Password' }
                    },
                    required: %w[username password]
                  }
                },
                required: %w[host credentials]
              }
            },
            required: ['database']
          )
        end
      end

      context 'with Hash containing Array' do
        let(:key) { :assets }
        let(:param_options) do
          {
            type: 'Hash',
            desc: 'Object that contains assets for the release',
            required: false,
            params: {
              links: {
                type: 'Array',
                desc: 'Link information about the release',
                required: false,
                params: {
                  name: { type: 'String', desc: 'The name of the link', required: true },
                  url: { type: 'String', desc: 'The URL of the link', required: true },
                  direct_asset_path: { type: 'String', desc: 'Optional path for a direct asset link', required: false }
                }
              }
            }
          }
        end

        it 'generates complete nested object containing array of objects' do
          expect(method_call).to eq(
            type: 'object',
            description: 'Object that contains assets for the release',
            properties: {
              'links' => {
                type: 'array',
                description: 'Link information about the release',
                items: {
                  type: 'object',
                  properties: {
                    'name' => { type: 'string', description: 'The name of the link' },
                    'url' => { type: 'string', description: 'The URL of the link' },
                    'direct_asset_path' => { type: 'string', description: 'Optional path for a direct asset link' }
                  },
                  required: %w[name url]
                }
              }
            }
          )
        end
      end
    end

    describe 'when no special conditions match (basic types)' do
      let(:key) { :field }

      context 'with string type' do
        let(:param_options) { { type: 'String', desc: 'User name', required: true } }

        it 'generates complete string schema' do
          expect(method_call).to eq(
            type: 'string',
            description: 'User name'
          )
        end
      end

      context 'with integer type' do
        let(:param_options) { { type: 'Integer', desc: 'User age', required: true } }

        it 'generates complete integer schema' do
          expect(method_call).to eq(
            type: 'integer',
            description: 'User age'
          )
        end
      end

      context 'with boolean type' do
        let(:param_options) { { type: 'Grape::API::Boolean', desc: 'Is active', required: true } }

        it 'generates complete boolean schema' do
          expect(method_call).to eq(
            type: 'boolean',
            description: 'Is active'
          )
        end
      end

      context 'with DateTime type' do
        let(:param_options) { { type: 'DateTime', desc: 'Creation time', required: true } }

        it 'generates complete datetime schema' do
          expect(method_call).to eq(
            type: 'string',
            format: 'date-time',
            description: 'Creation time'
          )
        end
      end

      context 'with Hash type (no nested params)' do
        let(:param_options) { { type: 'Hash', desc: 'Metadata object', required: true } }

        it 'generates complete object schema' do
          expect(method_call).to eq(
            type: 'object',
            description: 'Metadata object'
          )
        end
      end

      context 'with no type specified' do
        let(:param_options) { { desc: 'Some data', required: true } }

        it 'defaults to string type' do
          expect(method_call).to eq(
            type: 'string',
            description: 'Some data'
          )
        end
      end

      context 'with no description' do
        let(:param_options) { { type: 'String', required: true } }

        it 'generates schema without description' do
          expect(method_call).to eq(type: 'string')
        end
      end

      context 'with default value' do
        let(:param_options) { { type: 'String', desc: 'User role', required: false, default: 'member' } }

        it 'includes default in schema' do
          expect(method_call).to eq(
            type: 'string',
            description: 'User role',
            default: 'member'
          )
        end
      end

      context 'with example' do
        let(:param_options) do
          {
            type: 'String',
            desc: 'User email',
            required: true,
            documentation: { example: 'user@example.com' }
          }
        end

        it 'includes example in schema' do
          expect(method_call).to eq(
            type: 'string',
            description: 'User email',
            example: 'user@example.com'
          )
        end
      end

      context 'with regex validation' do
        let(:param_options) { { type: 'String', desc: 'Username', required: true } }
        let(:validations) do
          [
            {
              attributes: [:field],
              options: /^[a-z0-9_]+$/,
              validator_class: Grape::Validations::Validators::RegexpValidator
            }
          ]
        end

        it 'includes pattern in schema' do
          expect(method_call).to eq(
            type: 'string',
            description: 'Username',
            pattern: '^[a-z0-9_]+$'
          )
        end
      end

      context 'with all options combined' do
        let(:param_options) do
          {
            type: 'String',
            desc: 'Username',
            required: false,
            default: 'guest',
            documentation: { example: 'john_doe' }
          }
        end

        let(:validations) do
          [
            {
              attributes: [:field],
              options: /^[a-z_]+$/,
              validator_class: Grape::Validations::Validators::RegexpValidator
            }
          ]
        end

        it 'generates complete schema with all options' do
          expect(method_call).to eq(
            type: 'string',
            default: 'guest',
            description: 'Username',
            example: 'john_doe',
            pattern: '^[a-z_]+$'
          )
        end
      end

      context 'with Proc default value' do
        let(:param_options) { { type: 'String', desc: 'Dynamic default', required: false, default: -> { 'computed' } } }

        it 'generates schema without default when default is a Proc' do
          expect(method_call).to eq(
            type: 'string',
            description: 'Dynamic default'
          )
        end
      end

      context 'with lambda default value' do
        let(:param_options) { { type: 'Integer', required: false, default: -> { Time.current.to_i } } }

        it 'generates schema without default when default is a lambda' do
          expect(method_call).to eq(
            type: 'integer'
          )
        end
      end
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
