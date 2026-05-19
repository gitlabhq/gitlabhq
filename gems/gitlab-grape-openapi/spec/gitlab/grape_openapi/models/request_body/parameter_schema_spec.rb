# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles
RSpec.describe Gitlab::GrapeOpenapi::Models::RequestBody::ParameterSchema do
  subject(:parameter_schema) do
    described_class.new(route: route, key: key, param_options: param_options)
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
      parameter_schema.build
    end

    describe 'allow_blank behavior' do
      let(:key) { :name }

      context 'when allow_blank is not set' do
        let(:param_options) { { type: 'String', required: false } }

        it 'adds nullable: true' do
          expect(method_call[:nullable]).to be true
        end
      end

      context 'when allow_blank: true' do
        let(:param_options) { { type: 'String', allow_blank: true, required: false } }

        it 'adds nullable: true' do
          expect(method_call[:nullable]).to be true
        end
      end

      context 'when allow_blank: false with a string type' do
        let(:param_options) { { type: 'String', allow_blank: false, required: false } }

        it 'adds minLength: 1 and omits nullable' do
          expect(method_call[:minLength]).to eq(1)
          expect(method_call[:nullable]).to be_nil
        end
      end

      context 'when allow_blank: false with a non-string type' do
        let(:param_options) { { type: 'Integer', allow_blank: false, required: false } }

        it 'omits both nullable and minLength' do
          expect(method_call[:nullable]).to be_nil
          expect(method_call[:minLength]).to be_nil
        end
      end

      context 'when params are required with a values constraint' do
        let(:param_options) { { type: 'String', required: true, values: %w[foo bar] } }

        it 'adds minLength: 1 and omits nullable' do
          expect(method_call[:minLength]).to eq(1)
          expect(method_call[:nullable]).to be_nil
        end
      end

      context 'when params are optional with a values constraint' do
        let(:param_options) { { type: 'String', required: false, values: %w[foo bar] } }

        it 'adds nullable: true' do
          expect(method_call[:nullable]).to be true
        end
      end

      context 'when parameter has multiple types (oneOf schema)' do
        let(:param_options) { { type: '[String, Integer]', required: false } }

        it 'adds nullable: true to each oneOf member instead of the top level' do
          expect(method_call[:nullable]).to be_nil
          expect(method_call[:oneOf]).to all(include(nullable: true))
        end
      end

      context 'when parameter has multiple types and allow_blank: false' do
        let(:param_options) { { type: '[String, Integer]', allow_blank: false, required: false } }

        it 'omits nullable from all oneOf members' do
          expect(method_call[:nullable]).to be_nil
          expect(method_call[:oneOf]).to all(satisfy { |s| !s.key?(:nullable) })
        end
      end
    end

    describe 'limit validation behaviour' do
      let(:key) { :name }

      context 'with limit validation on a string type' do
        let(:param_options) { { type: 'String', desc: 'Username', required: false } }
        let(:validations) do
          [{
            attributes: [:name],
            options: 255,
            validator_class: API::Validations::Validators::Limit
          }]
        end

        it 'includes maxLength in schema' do
          expect(method_call).to eq(
            type: 'string',
            description: 'Username',
            maxLength: 255,
            nullable: true
          )
        end

        context 'when limit and allow_blank: false combined' do
          let(:param_options) { { type: 'String', desc: 'Username', required: false, allow_blank: false } }
          let(:validations) do
            [{
              attributes: [:name],
              options: 255,
              validator_class: API::Validations::Validators::Limit
            }]
          end

          it 'sets both minLength and maxLength' do
            expect(method_call).to eq(
              type: 'string',
              description: 'Username',
              minLength: 1,
              maxLength: 255
            )
          end
        end

        context 'when limit is zero' do
          let(:param_options) { { type: 'String', required: false } }
          let(:validations) do
            [{ attributes: [:field], options: 0, validator_class: API::Validations::Validators::Limit }]
          end

          it 'does not set maxLength' do
            expect(method_call[:maxLength]).to be_nil
          end
        end

        context 'when limit is negative' do
          let(:param_options) { { type: 'String', required: false } }
          let(:validations) do
            [{ attributes: [:field], options: -1, validator_class: API::Validations::Validators::Limit }]
          end

          it 'does not set maxLength' do
            expect(method_call[:maxLength]).to be_nil
          end
        end

        context 'when limit is not an integer' do
          let(:param_options) { { type: 'String', required: false } }
          let(:validations) do
            [{ attributes: [:field], options: "five", validator_class: API::Validations::Validators::Limit }]
          end

          it 'does not set maxLength' do
            expect(method_call[:maxLength]).to be_nil
          end
        end
      end

      context 'with limit validation on a non-string type' do
        let(:param_options) { { type: 'Integer', desc: 'Count', required: false } }
        let(:validations) do
          [{
            attributes: [:name],
            options: 100,
            validator_class: API::Validations::Validators::Limit
          }]
        end

        it 'does not include maxLength' do
          expect(method_call[:maxLength]).to be_nil
        end
      end
    end

    describe 'when type starts with "[" and has no comma (e.g., [String])' do
      let(:key) { :items }

      context 'with [String] notation' do
        let(:param_options) { { type: '[String]', desc: 'Milestone titles', required: false } }

        it 'generates complete array schema' do
          expect(method_call).to eq(
            type: 'array',
            items: { type: 'string' },
            description: 'Milestone titles',
            nullable: true
          )
        end
      end

      context 'with [Integer] notation' do
        let(:param_options) { { type: '[Integer]', desc: 'IDs', required: true } }

        it 'generates complete array schema with integer items' do
          expect(method_call).to eq(
            type: 'array',
            items: { type: 'integer' },
            description: 'IDs',
            nullable: true
          )
        end
      end

      context 'without description' do
        let(:param_options) { { type: '[String]', required: true } }

        it 'generates array schema without description' do
          expect(method_call).to eq(
            type: 'array',
            items: { type: 'string' },
            nullable: true
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
              { type: 'string', nullable: true },
              { type: 'integer', nullable: true }
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
              description: 'User profile picture',
              nullable: true
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
              description: 'User profile picture',
              nullable: true
            }
          )
        end
      end
    end

    describe 'when values is a Range' do
      let(:key) { :position }

      context 'with integer range' do
        let(:param_options) { { type: 'Integer', desc: 'Position', required: true, values: (1..20) } }

        it 'generates complete range schema without nullable' do
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

        it 'generates range schema without description or nullable' do
          expect(method_call).to eq(
            type: 'integer',
            minimum: 5,
            maximum: 10
          )
        end
      end

      context 'with default value' do
        let(:param_options) { { type: 'Integer', desc: 'Limit', required: false, values: 1..1000, default: 100 } }

        it 'includes both range and default' do
          expect(method_call).to eq(
            type: 'integer',
            minimum: 1,
            maximum: 1000,
            default: 100,
            description: 'Limit',
            nullable: true
          )
        end
      end

      context 'with Proc default value' do
        let(:param_options) { { type: 'Integer', required: false, values: 1..100, default: -> { 50 } } }

        it 'does not include Proc default (because the value is computed at runtime)' do
          expect(method_call).to eq(
            type: 'integer',
            minimum: 1,
            maximum: 100,
            nullable: true
          )
        end
      end

      context 'with Time object default' do
        let(:param_options) { { type: 'Integer', required: false, values: 1..100, default: Time.current } }

        it 'does not include Time default (not serializable)' do
          expect(method_call).to eq(
            type: 'integer',
            minimum: 1,
            maximum: 100,
            nullable: true
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

        it 'generates complete enum schema with minLength' do
          expect(method_call).to eq(
            type: 'string',
            enum: %w[active inactive pending],
            description: 'User status',
            minLength: 1
          )
        end
      end

      context 'without description' do
        let(:param_options) { { type: 'String', required: true, values: %w[yes no] } }

        it 'generates enum schema with minLength' do
          expect(method_call).to eq(
            type: 'string',
            enum: %w[yes no],
            minLength: 1
          )
        end
      end

      context 'with Proc enum values' do
        let(:param_options) { { type: 'String', desc: 'Dynamic values', required: true, values: -> { %w[a b c] } } }

        it 'generates schema without enum and with minLength' do
          expect(method_call).to eq(
            type: 'string',
            description: 'Dynamic values',
            minLength: 1
          )
        end
      end

      context 'with lambda enum values' do
        let(:param_options) { { type: 'Integer', required: true, values: -> { [1, 2, 3] } } }

        it 'generates schema without enum or nullable' do
          expect(method_call).to eq(
            type: 'integer'
          )
        end
      end

      context 'with enum and default value' do
        let(:param_options) do
          { type: 'String', desc: 'Priority', required: false, values: %w[low medium high], default: 'medium' }
        end

        it 'includes both enum and default' do
          expect(method_call).to eq(
            type: 'string',
            enum: %w[low medium high],
            default: 'medium',
            description: 'Priority',
            nullable: true
          )
        end
      end

      context 'with enum and Proc default value (because the value is computed at runtime)' do
        let(:param_options) do
          { type: 'String', required: false, values: %w[low medium high], default: -> { 'medium' } }
        end

        it 'includes enum but not Proc default' do
          expect(method_call).to eq(
            type: 'string',
            enum: %w[low medium high],
            nullable: true
          )
        end
      end

      context 'with enum and Time object default' do
        let(:param_options) do
          { type: 'String', required: false, values: %w[low medium high], default: Time.current }
        end

        it 'includes enum but not Time default (not serializable)' do
          expect(method_call).to eq(
            type: 'string',
            enum: %w[low medium high],
            nullable: true
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
            nullable: true,
            items: {
              type: 'object',
              properties: {
                'name' => { type: 'string', description: 'Item name', nullable: true },
                'quantity' => { type: 'integer', description: 'Quantity', nullable: true },
                'notes' => { type: 'string', description: 'Optional notes', nullable: true }
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
            nullable: true,
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
            nullable: true,
            items: {
              type: 'object',
              properties: {
                'label' => { type: 'string', description: 'Label', nullable: true }
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
            description: 'User tags',
            nullable: true
          )
        end
      end

      context 'without description' do
        let(:param_options) { { type: 'Array[Integer]', required: true } }

        it 'generates array schema without description' do
          expect(method_call).to eq(
            type: 'array',
            items: { type: 'arrayinteger' },
            nullable: true
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
            nullable: true,
            properties: {
              'title' => { type: 'string', description: 'Title', nullable: true },
              'description' => { type: 'string', description: 'Description', nullable: true },
              'version' => { type: 'integer', description: 'Version number', nullable: true }
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
            description: 'Empty hash',
            nullable: true
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
            nullable: true,
            properties: {
              'database' => {
                type: 'object',
                description: 'Database configuration',
                nullable: true,
                properties: {
                  'host' => { type: 'string', description: 'Database host', nullable: true },
                  'port' => { type: 'integer', description: 'Database port', default: 5432, nullable: true },
                  'credentials' => {
                    type: 'object',
                    description: 'Database credentials',
                    nullable: true,
                    properties: {
                      'username' => { type: 'string', description: 'Username', nullable: true },
                      'password' => { type: 'string', description: 'Password', nullable: true }
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
            nullable: true,
            properties: {
              'links' => {
                type: 'array',
                description: 'Link information about the release',
                nullable: true,
                items: {
                  type: 'object',
                  properties: {
                    'name' => { type: 'string', description: 'The name of the link', nullable: true },
                    'url' => { type: 'string', description: 'The URL of the link', nullable: true },
                    'direct_asset_path' => { type: 'string', description: 'Optional path for a direct asset link',
                                             nullable: true }
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
            description: 'User name',
            nullable: true
          )
        end
      end

      context 'with integer type' do
        let(:param_options) { { type: 'Integer', desc: 'User age', required: true } }

        it 'generates complete integer schema' do
          expect(method_call).to eq(
            type: 'integer',
            description: 'User age',
            nullable: true
          )
        end
      end

      context 'with boolean type' do
        let(:param_options) { { type: 'Grape::API::Boolean', desc: 'Is active', required: true } }

        it 'generates complete boolean schema' do
          expect(method_call).to eq(
            type: 'boolean',
            description: 'Is active',
            nullable: true
          )
        end
      end

      context 'with DateTime type' do
        let(:param_options) { { type: 'DateTime', desc: 'Creation time', required: true } }

        it 'generates complete datetime schema' do
          expect(method_call).to eq(
            type: 'string',
            format: 'date-time',
            description: 'Creation time',
            nullable: true
          )
        end
      end

      context 'with Hash type (no nested params)' do
        let(:param_options) { { type: 'Hash', desc: 'Metadata object', required: true } }

        it 'generates complete object schema' do
          expect(method_call).to eq(
            type: 'object',
            description: 'Metadata object',
            nullable: true
          )
        end
      end

      context 'with no type specified' do
        let(:param_options) { { desc: 'Some data', required: true } }

        it 'defaults to string type' do
          expect(method_call).to eq(
            type: 'string',
            description: 'Some data',
            nullable: true
          )
        end
      end

      context 'with no description' do
        let(:param_options) { { type: 'String', required: true } }

        it 'generates schema without description' do
          expect(method_call).to eq(type: 'string', nullable: true)
        end
      end

      context 'with default value' do
        let(:param_options) { { type: 'String', desc: 'User role', required: false, default: 'member' } }

        it 'includes default in schema' do
          expect(method_call).to eq(
            type: 'string',
            description: 'User role',
            default: 'member',
            nullable: true
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
            example: 'user@example.com',
            nullable: true
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
            pattern: '(?<=^|\n(?!$))[a-z0-9_]+(?=$|\n)',
            nullable: true
          )
        end
      end

      context 'with regex validation using Ruby-only constructs' do
        let(:param_options) { { type: 'String', desc: 'Distribution', required: true } }
        let(:validations) do
          [
            {
              attributes: [:field],
              options: /\A(?i-mx:[a-z0-9][a-z0-9.-]*)\z/,
              validator_class: Grape::Validations::Validators::RegexpValidator
            }
          ]
        end

        it 'converts the pattern to ECMA-262 syntax with case-folding baked in' do
          expect(method_call).to eq(
            type: 'string',
            description: 'Distribution',
            pattern: '^(?:[0-9A-Za-z\u017F\u212A][\x2D.0-9A-Za-z\u017F\u212A]*)$',
            nullable: true
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
            pattern: '(?<=^|\n(?!$))[a-z_]+(?=$|\n)',
            nullable: true
          )
        end
      end

      context 'with Proc default value' do
        let(:param_options) { { type: 'String', desc: 'Dynamic default', required: false, default: -> { 'computed' } } }

        it 'generates schema without default when default is a Proc' do
          expect(method_call).to eq(
            type: 'string',
            description: 'Dynamic default',
            nullable: true
          )
        end
      end

      context 'with lambda default value' do
        let(:param_options) { { type: 'Integer', required: false, default: -> { Time.current.to_i } } }

        it 'generates schema without default when default is a lambda' do
          expect(method_call).to eq(
            type: 'integer',
            nullable: true
          )
        end
      end

      context 'with Time object default' do
        let(:param_options) { { type: 'String', required: false, default: Time.current } }

        it 'generates schema without default when default is a Time (not serializable)' do
          expect(method_call).to eq(
            type: 'string',
            nullable: true
          )
        end
      end
    end

    describe "coercer mappings" do
      before do
        Gitlab::GrapeOpenapi.configuration.coercer_mappings = {
          "CommaSeparatedToArray" => {
            type: "array",
            items_type: "string",
            style: "form",
            explode: false
          },
          "CommaSeparatedToIntegerArray" => {
            type: "array",
            items_type: "integer",
            style: "form",
            explode: false
          },
          "HashOfIntegerValues" => {
            type: "object",
            additional_properties: { type: "integer" }
          },
          "HashWithDirectAdditionalProperties" => {
            type: "object",
            additional_properties: { type: "string", format: "date-time" }
          },
          "urlsafe_decode64" => {
            type: "string",
            format: "byte"
          }
        }
      end

      after do
        Gitlab::GrapeOpenapi.configuration.coercer_mappings = {}
      end

      context "when coerce_with matches CommaSeparatedToArray" do
        let(:key) { :labels }
        let(:param_options) { { type: "[String]", desc: "Comma-separated labels", required: false } }

        let(:validations) do
          [
            {
              attributes: [:labels],
              options: {
                type: Array,
                method: TestValidations::Types::CommaSeparatedToArray.coerce
              },
              validator_class: Grape::Validations::Validators::CoerceValidator
            }
          ]
        end

        it "generates array schema with string items" do
          expect(method_call).to eq(
            { type: "array", items: { type: "string" }, description: "Comma-separated labels", nullable: true }
          )
        end
      end

      context "when coerce_with matches CommaSeparatedToIntegerArray" do
        let(:key) { :ids }
        let(:param_options) { { type: "[Integer]", desc: "Comma-separated IDs", required: true } }

        let(:validations) do
          [
            {
              attributes: [:ids],
              options: {
                type: Array,
                method: TestValidations::Types::CommaSeparatedToIntegerArray.coerce
              },
              validator_class: Grape::Validations::Validators::CoerceValidator
            }
          ]
        end

        it "generates array schema with integer items" do
          expect(method_call).to eq(
            { type: "array", items: { type: "integer" }, description: "Comma-separated IDs", nullable: true }
          )
        end
      end

      context "when coerce_with matches HashOfIntegerValues" do
        let(:key) { :counts }
        let(:param_options) { { type: "Hash", desc: "Counts by category", required: false } }

        let(:validations) do
          [
            {
              attributes: [:counts],
              options: {
                type: Hash,
                method: TestValidations::Types::HashOfIntegerValues.coerce
              },
              validator_class: Grape::Validations::Validators::CoerceValidator
            }
          ]
        end

        it "generates object schema with additionalProperties" do
          expect(method_call).to eq(
            {
              type: "object",
              additionalProperties: { type: "integer" },
              description: "Counts by category",
              nullable: true
            }
          )
        end
      end

      context "when coerce_with matches urlsafe_decode64" do
        let(:key) { :encoded_data }
        let(:param_options) { { type: "String", desc: "Base64-encoded data", required: false } }

        let(:validations) do
          [
            {
              attributes: [:encoded_data],
              options: { type: String, method: Struct.new(:name).new(:urlsafe_decode64) },
              validator_class: Grape::Validations::Validators::CoerceValidator
            }
          ]
        end

        it "generates string schema with byte format" do
          expect(method_call).to eq(
            { type: "string", format: "byte", description: "Base64-encoded data", nullable: true }
          )
        end
      end

      context "when no coercer mapping matches a named coercer" do
        let(:key) { :data }
        let(:param_options) { { type: "String", desc: "Some data", required: true } }

        let(:validations) do
          [
            {
              attributes: [:data],
              options: {
                type: String,
                method: TestValidations::Types::SomeUnknownCoercer.coerce
              },
              validator_class: Grape::Validations::Validators::CoerceValidator
            }
          ]
        end

        it "raises an error" do
          expect do
            method_call
          end.to raise_error(Gitlab::GrapeOpenapi::GenerationError, /No OpenAPI schema mapping found for coercer/)
        end
      end

      context "when no coercer mapping matches an inline lambda" do
        let(:key) { :data }
        let(:param_options) { { type: "String", desc: "Some data", required: true } }

        let(:validations) do
          [
            {
              attributes: [:data],
              options: { type: String, method: ->(v) { v.downcase } },
              validator_class: Grape::Validations::Validators::CoerceValidator
            }
          ]
        end

        it "falls back to default schema generation" do
          expect(method_call).to eq({ type: "string", description: "Some data", nullable: true })
        end
      end

      context "when no coerce validation exists" do
        let(:key) { :name }
        let(:param_options) { { type: "String", desc: "A name", required: true } }

        let(:validations) do
          [
            {
              attributes: [:name],
              options: /^[a-z]+$/,
              validator_class: Grape::Validations::Validators::RegexpValidator
            }
          ]
        end

        it "falls back to default schema generation with pattern" do
          expect(method_call).to eq({ type: "string", description: "A name", pattern: "(?<=^|\\n(?!$))[a-z]+(?=$|\\n)",
nullable: true })
        end
      end

      context "when coercer_mappings is empty with a named coercer" do
        before do
          Gitlab::GrapeOpenapi.configuration.coercer_mappings = {}
        end

        let(:key) { :labels }
        let(:param_options) { { type: "[String]", desc: "Labels", required: false } }

        let(:validations) do
          [
            {
              attributes: [:labels],
              options: {
                type: Array,
                method: TestValidations::Types::CommaSeparatedToArray.coerce
              },
              validator_class: Grape::Validations::Validators::CoerceValidator
            }
          ]
        end

        it "raises an error" do
          expect do
            method_call
          end.to raise_error(Gitlab::GrapeOpenapi::GenerationError, /No OpenAPI schema mapping found for coercer/)
        end
      end

      context "when coercer_mappings is empty with an inline lambda" do
        before do
          Gitlab::GrapeOpenapi.configuration.coercer_mappings = {}
        end

        let(:key) { :labels }
        let(:param_options) { { type: "[String]", desc: "Labels", required: false } }

        let(:validations) do
          [
            {
              attributes: [:labels],
              options: { type: Array, method: ->(v) { v } },
              validator_class: Grape::Validations::Validators::CoerceValidator
            }
          ]
        end

        it "falls back to default schema generation (array for bracket notation)" do
          expect(method_call).to eq(
            { type: "array", items: { type: "string" }, description: "Labels", nullable: true }
          )
        end
      end
    end

    describe 'fail_fast annotation' do
      let(:key) { :name }

      context 'with fail_fast: true in validations' do
        let(:param_options) { { type: 'String', required: true, desc: 'A name' } }
        let(:validations) do
          [{ attributes: [:name], opts: { fail_fast: true },
             validator_class: Grape::Validations::Validators::PresenceValidator }]
        end

        it 'appends annotation to description' do
          expect(method_call).to eq(
            type: 'string',
            description: 'A name (validation stops on first error)',
            nullable: true
          )
        end
      end

      context 'with fail_fast: true in validations and annotation already present' do
        let(:param_options) { { type: 'String', required: true, desc: 'A name (validation stops on first error)' } }
        let(:validations) do
          [{ attributes: [:name], opts: { fail_fast: true },
             validator_class: Grape::Validations::Validators::PresenceValidator }]
        end

        it 'does not duplicate the annotation' do
          expect(method_call).to eq(
            type: 'string',
            description: 'A name (validation stops on first error)',
            nullable: true
          )
        end
      end

      context 'without fail_fast' do
        let(:param_options) { { type: 'String', required: true, desc: 'A name' } }

        it 'leaves description unchanged' do
          expect(method_call).to eq(
            type: 'string',
            description: 'A name',
            nullable: true
          )
        end
      end
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
