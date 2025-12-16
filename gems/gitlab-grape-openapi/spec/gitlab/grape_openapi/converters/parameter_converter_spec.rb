# frozen_string_literal: true

# rubocop:disable RSpec/MultipleMemoizedHelpers, RSpec/VerifiedDoubles
RSpec.describe Gitlab::GrapeOpenapi::Converters::ParameterConverter do
  let(:route) { double('route', path: '/api/v1/:id/:user_id', instance_variable_get: { method: 'GET' }) }
  let(:required) { true }
  let(:type) { 'String' }
  let(:name) { "active" }
  let(:options) { { required: required, desc: "Filter by active users", type: type } }
  let(:validations) { [] }

  subject(:parameter) do
    described_class.convert(name, options: options, validations: validations, route: route)
  end

  describe '#in_value' do
    let(:converter) { described_class.new(name, options: options, validations: validations, route: route) }

    context 'when parameter is in path' do
      let(:name) { "user_id" }

      it 'returns path as the in_value' do
        expect(converter.in_value).to eq('path')
      end
    end

    context 'when parameter is not in path' do
      let(:name) { "hello_world" }

      it 'returns query as the in_value' do
        expect(converter.in_value).to eq('query')
      end
    end

    context 'when parameter name matches path segment' do
      let(:name) { "id" }

      it 'returns path as the in_value' do
        expect(converter.in_value).to eq('path')
      end
    end

    context 'with different route path structures' do
      context 'when route has version placeholder' do
        let(:route) do
          double('Route', path: "/api/version/:project_id/users", instance_variable_get: { method: 'GET' })
        end

        let(:name) { "project_id" }

        it 'correctly identifies path parameter ignoring version' do
          expect(converter.in_value).to eq('path')
        end
      end

      context 'when route has no path parameters' do
        let(:route) { double('Route', path: "/api/v1/users", instance_variable_get: { method: 'GET' }) }
        let(:name) { "filter" }

        it 'returns query for any parameter' do
          expect(converter.in_value).to eq('query')
        end
      end

      context 'when route path contains version that should be ignored' do
        let(:route) do
          double('Route', path: "/api/version/:user_id/profile", instance_variable_get: { method: 'GET' })
        end

        let(:name) { "user_id" }

        it 'correctly identifies path parameter after version removal' do
          expect(converter.in_value).to eq('path')
        end
      end

      context 'when multiple path parameters exist' do
        let(:route) do
          double(
            'Route',
            path: "/api/v1/:org_id/:project_id/:user_id",
            instance_variable_get: { method: 'GET' }
          )
        end

        context 'with first parameter' do
          let(:name) { "org_id" }

          it 'identifies as path parameter' do
            expect(converter.in_value).to eq('path')
          end
        end

        context 'with middle parameter' do
          let(:name) { "project_id" }

          it 'identifies as path parameter' do
            expect(converter.in_value).to eq('path')
          end
        end

        context 'with last parameter' do
          let(:name) { "user_id" }

          it 'identifies as path parameter' do
            expect(converter.in_value).to eq('path')
          end
        end
      end
    end
  end

  describe '.convert' do
    context 'with GET requests' do
      it 'returns a Gitlab::GrapeOpenapi::Models::Parameter instance' do
        expect(parameter).to be_a(Gitlab::GrapeOpenapi::Models::Parameter)
      end

      it 'sets the name value correctly' do
        expect(parameter.name).to eq('active')
      end

      it 'sets the desc value correctly' do
        expect(parameter.description).to eq('Filter by active users')
      end

      it 'sets the in_value based on path detection' do
        expect(parameter.in_value).to eq('query')
      end

      context 'when required' do
        let(:required) { true }

        it 'sets required to true' do
          expect(parameter.required).to be true
        end
      end

      context 'when optional' do
        let(:required) { false }

        it 'sets required to false' do
          expect(parameter.required).to be false
        end
      end

      context 'when type is String' do
        let(:type) { 'String' }

        it 'sets schema type to string' do
          expect(parameter.schema[:type]).to eq('string')
        end
      end

      context 'when type is Boolean' do
        let(:type) { 'Grape::API::Boolean' }

        it 'sets schema type to boolean' do
          expect(parameter.schema[:type]).to eq('boolean')
        end
      end

      context 'when type is Integer' do
        let(:type) { 'Integer' }

        it 'sets schema type to integer' do
          expect(parameter.schema[:type]).to eq('integer')
        end
      end

      context 'when type is Hash' do
        let(:type) { 'Hash' }

        it 'sets schema type to object' do
          expect(parameter.schema[:type]).to eq('object')
        end
      end

      context 'when multiple types are allowed (union)' do
        let(:type) { "[String, Integer]" }

        it 'sets schema as oneOf with resolved types' do
          expect(parameter.schema).to eq({ oneOf: [{ type: 'string' }, { type: 'integer' }] })
        end
      end

      context 'when union includes Boolean' do
        let(:type) { "[String, Grape::API::Boolean]" }

        it 'resolves Boolean type correctly' do
          expect(parameter.schema).to eq({ oneOf: [{ type: 'string' }, { type: 'boolean' }] })
        end
      end

      context 'when values are defined (enum)' do
        let(:options) { { required: required, desc: "Filter by status", type: type, values: %w[foo bar baz] } }

        it 'defines enum in output' do
          expect(parameter.schema).to eq({ type: 'string', enum: %w[foo bar baz] })
        end
      end

      context 'when enum with integer values' do
        let(:type) { 'Integer' }
        let(:options) { { required: required, desc: "Priority level", type: type, values: [1, 2, 3] } }

        it 'defines enum with integer type' do
          expect(parameter.schema).to eq({ type: 'integer', enum: [1, 2, 3] })
        end
      end

      context 'when a default is defined' do
        let(:options) { { required: required, desc: "Filter by active users", type: type, default: 'foo' } }

        it 'returns the default value within the schema' do
          expect(parameter.schema).to eq({ type: 'string', default: 'foo' })
        end
      end

      context 'when default is a boolean' do
        let(:type) { 'Grape::API::Boolean' }
        let(:options) { { required: required, desc: "Active flag", type: type, default: true } }

        it 'includes boolean default when true' do
          expect(parameter.schema).to eq({ type: 'boolean', default: true })
        end
      end

      context 'when default is an integer' do
        let(:type) { 'Integer' }
        let(:options) { { required: required, desc: "Page number", type: type, default: 1 } }

        it 'includes integer default' do
          expect(parameter.schema).to eq({ type: 'integer', default: 1 })
        end
      end

      context 'when an example is defined' do
        let(:options) do
          { required: required, desc: "Filter by active users", type: type, documentation: { example: 'abcd' } }
        end

        it 'returns the example value' do
          expect(parameter.example).to eq('abcd')
        end
      end

      context 'when example is a complex value' do
        let(:options) do
          { required: required, desc: "User ID", type: type, documentation: { example: 12345 } }
        end

        it 'returns the example value' do
          expect(parameter.example).to eq(12345)
        end
      end

      context 'when parameter is a DateTime' do
        let(:options) { { required: required, desc: "Example datetime", type: 'DateTime' } }

        it 'returns string type with date-time format' do
          expect(parameter.schema[:type]).to eq('string')
          expect(parameter.schema[:format]).to eq('date-time')
        end
      end

      context 'when parameter is DateTime with default' do
        let(:options) { { required: required, desc: "Created at", type: 'DateTime', default: '2023-01-01T00:00:00Z' } }

        it 'includes format and default' do
          expect(parameter.schema).to eq({
            type: 'string',
            format: 'date-time',
            default: '2023-01-01T00:00:00Z'
          })
        end
      end
    end

    context 'with non-GET requests that have request bodies' do
      %w[POST PUT PATCH HEAD OPTIONS].each do |http_method|
        context "with #{http_method} request" do
          let(:route) do
            double('Route', path: "/api/v1/:id/:user_id", instance_variable_get: { method: http_method })
          end

          context 'when parameter is in query (not path)' do
            let(:name) { "filter" }

            it 'returns nil because non-GET query params should be in request body' do
              expect(parameter).to be_nil
            end
          end

          context 'when parameter is in path' do
            let(:name) { "user_id" }

            it 'returns a Parameter instance because path parameters are always included' do
              expect(parameter).to be_a(Gitlab::GrapeOpenapi::Models::Parameter)
              expect(parameter.in_value).to eq('path')
            end
          end

          context 'when multiple path parameters' do
            let(:name) { "id" }

            it 'includes path parameter' do
              expect(parameter).to be_a(Gitlab::GrapeOpenapi::Models::Parameter)
              expect(parameter.in_value).to eq('path')
              expect(parameter.name).to eq('id')
            end
          end
        end
      end
    end

    context 'with DELETE requests' do
      let(:route) do
        double('Route', path: "/api/v1/:id/:user_id", instance_variable_get: { method: 'DELETE' })
      end

      context 'when parameter is in query (not path)' do
        let(:name) { "filter" }

        it 'returns a Parameter instance because DELETE has no request body, like GET' do
          expect(parameter).to be_a(Gitlab::GrapeOpenapi::Models::Parameter)
          expect(parameter.in_value).to eq('query')
        end
      end

      context 'when parameter is in path' do
        let(:name) { "user_id" }

        it 'returns a Parameter instance because path parameters are always included' do
          expect(parameter).to be_a(Gitlab::GrapeOpenapi::Models::Parameter)
          expect(parameter.in_value).to eq('path')
        end
      end

      context 'when multiple path parameters' do
        let(:name) { "id" }

        it 'includes path parameter' do
          expect(parameter).to be_a(Gitlab::GrapeOpenapi::Models::Parameter)
          expect(parameter.in_value).to eq('path')
          expect(parameter.name).to eq('id')
        end
      end
    end

    context 'with edge cases' do
      context 'when parameter has no type specified' do
        let(:options) { { required: required, desc: "Unknown type param" } }

        it 'defaults to string type' do
          expect(parameter.schema[:type]).to eq('string')
        end
      end

      context 'when parameter has empty options' do
        let(:options) { {} }

        it 'creates parameter with minimal schema' do
          expect(parameter).to be_a(Gitlab::GrapeOpenapi::Models::Parameter)
          expect(parameter.schema[:type]).to eq('string')
        end
      end

      context 'when description is missing' do
        let(:options) { { required: required, type: type } }

        it 'creates parameter without description' do
          expect(parameter).to be_a(Gitlab::GrapeOpenapi::Models::Parameter)
        end
      end
    end
  end

  describe 'schema generation' do
    let(:converter) { described_class.new(name, options: options, validations: validations, route: route) }

    describe 'array types' do
      context 'when type is [String] (single type in brackets)' do
        let(:options) { { type: '[String]' } }

        it 'generates oneOf schema with single string type' do
          expect(converter.schema).to eq({ oneOf: [{ type: 'string' }] })
        end
      end

      context 'when type is [Integer] (single type in brackets)' do
        let(:options) { { type: '[Integer]' } }

        it 'generates oneOf schema with single integer type' do
          expect(converter.schema).to eq({ oneOf: [{ type: 'integer' }] })
        end
      end
    end

    describe 'union types (oneOf)' do
      context 'with two types' do
        let(:options) { { type: '[String, Integer]' } }

        it 'generates oneOf schema with both types' do
          expect(converter.schema).to eq({
            oneOf: [
              { type: 'string' },
              { type: 'integer' }
            ]
          })
        end
      end

      context 'with three types' do
        let(:options) { { type: '[String, Integer, Hash]' } }

        it 'generates oneOf schema with all types resolved' do
          expect(converter.schema).to eq({
            oneOf: [
              { type: 'string' },
              { type: 'integer' },
              { type: 'object' }
            ]
          })
        end
      end

      context 'with Grape::API::Boolean type' do
        let(:options) { { type: '[String, Grape::API::Boolean]' } }

        it 'resolves Grape Boolean type to boolean' do
          expect(converter.schema).to eq({
            oneOf: [
              { type: 'string' },
              { type: 'boolean' }
            ]
          })
        end
      end
    end

    describe 'enum values' do
      context 'with string enum' do
        let(:options) { { type: 'String', values: %w[active inactive pending] } }

        it 'generates enum schema' do
          expect(converter.schema).to eq({
            type: 'string',
            enum: %w[active inactive pending]
          })
        end
      end

      context 'with integer enum' do
        let(:options) { { type: 'Integer', values: [1, 2, 3, 5, 8] } }

        it 'generates enum schema with integer type' do
          expect(converter.schema).to eq({
            type: 'integer',
            enum: [1, 2, 3, 5, 8]
          })
        end
      end

      context 'with symbol enum' do
        let(:options) { { type: 'symbol', values: [:low, :medium, :high] } }

        it 'generates enum schema with string type' do
          expect(converter.schema).to eq({
            type: 'string',
            enum: [:low, :medium, :high]
          })
        end
      end

      context 'with empty enum' do
        let(:options) { { type: 'String', values: [] } }

        it 'generates enum schema with empty array' do
          expect(converter.schema).to eq({
            type: 'string',
            enum: []
          })
        end
      end
    end

    describe 'range values' do
      context 'with integer range' do
        let(:options) { { type: 'Integer', values: 1..20 } }

        it 'generates schema with minimum and maximum' do
          expect(converter.schema).to eq({
            type: 'integer',
            minimum: 1,
            maximum: 20
          })
        end
      end
    end

    describe 'default values' do
      context 'with string default' do
        let(:options) { { type: 'String', default: 'test' } }

        it 'includes default in schema' do
          expect(converter.schema).to eq({
            type: 'string',
            default: 'test'
          })
        end
      end

      context 'with boolean default (true)' do
        let(:options) { { type: 'Grape::API::Boolean', default: true } }

        it 'includes default in schema' do
          expect(converter.schema).to eq({
            type: 'boolean',
            default: true
          })
        end
      end

      context 'with boolean default (false)' do
        let(:options) { { type: 'Grape::API::Boolean', default: false } }

        it 'does not include false default due to falsey check' do
          expect(converter.schema).to eq({
            type: 'boolean'
          })
        end
      end

      context 'with integer default' do
        let(:options) { { type: 'Integer', default: 42 } }

        it 'includes default in schema' do
          expect(converter.schema).to eq({
            type: 'integer',
            default: 42
          })
        end
      end

      context 'with zero default' do
        let(:options) { { type: 'Integer', default: 0 } }

        it 'includes zero as default' do
          expect(converter.schema).to eq({
            type: 'integer',
            default: 0
          })
        end
      end

      context 'with nil default' do
        let(:options) { { type: 'String', default: nil } }

        it 'does not include nil default' do
          expect(converter.schema).to eq({ type: 'string' })
        end
      end
    end

    describe 'DateTime handling' do
      context 'with DateTime type' do
        let(:options) { { type: 'DateTime' } }

        it 'converts to string with date-time format' do
          expect(converter.schema).to eq({
            type: 'string',
            format: 'date-time'
          })
        end
      end

      context 'with DateTime and default value' do
        let(:options) { { type: 'DateTime', default: '2023-01-01T00:00:00Z' } }

        it 'includes default with proper format' do
          expect(converter.schema).to eq({
            type: 'string',
            format: 'date-time',
            default: '2023-01-01T00:00:00Z'
          })
        end
      end

      context 'with DateTime and example' do
        let(:options) { { type: 'DateTime', documentation: { example: '2024-01-01T12:00:00Z' } } }

        it 'includes format in schema' do
          expect(converter.schema).to eq({
            type: 'string',
            format: 'date-time'
          })
          expect(converter.example).to eq('2024-01-01T12:00:00Z')
        end
      end
    end

    describe 'complex combinations' do
      context 'with enum and default' do
        let(:options) { { type: 'String', values: %w[low medium high], default: 'medium' } }

        it 'includes enum but not default (enums take precedence)' do
          # Current implementation: build_enum_schema doesn't include default
          expect(converter.schema).to eq({
            type: 'string',
            enum: %w[low medium high]
          })
        end
      end

      context 'with enum of integers and default' do
        let(:options) { { type: 'Integer', values: [10, 20, 30], default: 20 } }

        it 'includes enum but not default' do
          expect(converter.schema).to eq({
            type: 'integer',
            enum: [10, 20, 30]
          })
        end
      end

      context 'with union types (no enum or default)' do
        let(:options) { { type: '[String, Integer]' } }

        it 'generates clean oneOf schema' do
          expect(converter.schema).to eq({
            oneOf: [{ type: 'string' }, { type: 'integer' }]
          })
        end
      end
    end

    describe 'type resolution' do
      context 'with String type' do
        let(:options) { { type: 'String' } }

        it 'resolves to string' do
          expect(converter.resolve_object_type).to eq('string')
        end
      end

      context 'with Integer type' do
        let(:options) { { type: 'Integer' } }

        it 'resolves to integer' do
          expect(converter.resolve_object_type).to eq('integer')
        end
      end

      context 'with Grape::API::Boolean type' do
        let(:options) { { type: 'Grape::API::Boolean' } }

        it 'resolves to boolean' do
          expect(converter.resolve_object_type).to eq('boolean')
        end
      end

      context 'with Hash type' do
        let(:options) { { type: 'Hash' } }

        it 'resolves to object' do
          expect(converter.resolve_object_type).to eq('object')
        end
      end

      context 'with DateTime type' do
        let(:options) { { type: 'DateTime' } }

        it 'resolves to string' do
          expect(converter.resolve_object_type).to eq('string')
        end
      end

      context 'with no type specified' do
        let(:options) { {} }

        it 'defaults to string' do
          expect(converter.resolve_object_type).to eq('string')
        end
      end
    end

    describe 'format resolution' do
      context 'with DateTime type' do
        let(:options) { { type: 'DateTime' } }

        it 'resolves format to date-time' do
          expect(converter.resolve_object_format).to eq('date-time')
        end
      end

      context 'with String type' do
        let(:options) { { type: 'String' } }

        it 'has no format' do
          expect(converter.resolve_object_format).to be_nil
        end
      end

      context 'with Integer type' do
        let(:options) { { type: 'Integer' } }

        it 'has no format' do
          expect(converter.resolve_object_format).to be_nil
        end
      end
    end
  end

  describe 'validations' do
    let(:converter) { described_class.new(name, options: options, validations: validations, route: route) }

    context 'when a regular expression is defined' do
      let(:validations) do
        [{
          attributes: [:version_prefix],
          options: /^[\d+.]+/,
          required: false,
          validator_class: Grape::Validations::Validators::RegexpValidator
        }]
      end

      it 'returns the correct schema with pattern' do
        expect(converter.schema).to eq({ type: 'string', pattern: '^[\d+.]+' })
      end
    end

    context 'when regex has complex pattern' do
      let(:validations) do
        [{
          attributes: [:email],
          options: /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/,
          required: false,
          validator_class: Grape::Validations::Validators::RegexpValidator
        }]
      end

      it 'extracts pattern correctly' do
        expect(converter.schema[:pattern]).to eq('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
      end
    end

    context 'when multiple validations are present but only regex is supported' do
      let(:validations) do
        [
          {
            attributes: [:version_prefix],
            options: /^[\d+.]+/,
            required: false,
            validator_class: Grape::Validations::Validators::RegexpValidator
          },
          {
            attributes: [:version_prefix],
            options: { min: 1, max: 10 },
            required: false,
            validator_class: double('LengthValidator')
          }
        ]
      end

      it 'only includes the regex pattern' do
        expect(converter.schema).to eq({ type: 'string', pattern: '^[\d+.]+' })
      end
    end

    context 'when no regex validation is present' do
      let(:validations) do
        [{
          attributes: [:version_prefix],
          options: { min: 1, max: 10 },
          required: false,
          validator_class: double('LengthValidator')
        }]
      end

      it 'does not include pattern' do
        expect(converter.schema).to eq({ type: 'string' })
      end
    end

    context 'when validations array is empty' do
      let(:validations) { [] }

      it 'does not include pattern' do
        expect(converter.schema).to eq({ type: 'string' })
      end
    end

    context 'when validations is nil' do
      let(:validations) { nil }

      it 'does not include pattern' do
        expect(converter.schema).to eq({ type: 'string' })
      end
    end

    context 'with regex validation and other schema properties' do
      let(:options) { { type: 'String', default: 'v1.0' } }
      let(:validations) do
        [{
          attributes: [:version_prefix],
          options: /^v[\d+.]+/,
          required: false,
          validator_class: Grape::Validations::Validators::RegexpValidator
        }]
      end

      it 'includes both pattern and default' do
        expect(converter.schema).to eq({
          type: 'string',
          default: 'v1.0',
          pattern: '^v[\d+.]+'
        })
      end
    end

    context 'with regex validation and enum' do
      let(:options) { { type: 'String', values: %w[v1.0 v2.0 v3.0] } }
      let(:validations) do
        [{
          attributes: [:version],
          options: /^v[\d+.]+/,
          required: false,
          validator_class: Grape::Validations::Validators::RegexpValidator
        }]
      end

      it 'enum takes precedence, no pattern included' do
        # Enum schema is returned before regex validations are added
        expect(converter.schema).to eq({
          type: 'string',
          enum: %w[v1.0 v2.0 v3.0]
        })
      end
    end

    context 'with regex validation and DateTime' do
      let(:options) { { type: 'DateTime' } }
      let(:validations) do
        [{
          attributes: [:timestamp],
          options: /^\d{4}-\d{2}-\d{2}/,
          required: false,
          validator_class: Grape::Validations::Validators::RegexpValidator
        }]
      end

      it 'includes format and pattern' do
        expect(converter.schema).to eq({
          type: 'string',
          format: 'date-time',
          pattern: '^\d{4}-\d{2}-\d{2}'
        })
      end
    end

    describe 'validations' do
      context 'when a regular expression is defined' do
        let(:validations) do
          [
            { attributes: [:version_prefix],
              options: /^[\d+.]+/,
              required: false,
              validator_class: Grape::Validations::Validators::RegexpValidator }
          ]
        end

        it 'returns the correct schema values' do
          expect(parameter.schema).to eq({ type: 'string', pattern: '^[\d+.]+' })
        end
      end

      context 'when validations is nil' do
        it 'does not raise error' do
          expect do
            described_class.convert(:user_id, options: { type: 'Integer' }, route: route,
              validations: nil)
          end.not_to raise_error
        end
      end

      context 'when validations has no regex validator' do
        it 'returns parameter without pattern' do
          result = described_class.convert(
            :user_id,
            options: { type: 'Integer' },
            route: route,
            validations: [{ attributes: [:user_id],
                            validator_class: Grape::Validations::Validators::PresenceValidator }]
          )

          expect(result.schema[:pattern]).to be_nil
        end
      end
    end
  end

  describe 'example handling' do
    let(:converter) { described_class.new(name, options: options, validations: validations, route: route) }

    context 'when example is provided in documentation' do
      let(:options) { { type: 'String', documentation: { example: 'test_value' } } }

      it 'extracts the example' do
        expect(converter.example).to eq('test_value')
      end
    end

    context 'when example is a number' do
      let(:options) { { type: 'Integer', documentation: { example: 12345 } } }

      it 'extracts numeric example' do
        expect(converter.example).to eq(12345)
      end
    end

    context 'when example is a boolean' do
      let(:options) { { type: 'Grape::API::Boolean', documentation: { example: true } } }

      it 'extracts boolean example' do
        expect(converter.example).to be(true)
      end
    end

    context 'when example is an array' do
      let(:options) { { type: 'Array', documentation: { example: [1, 2, 3] } } }

      it 'extracts array example' do
        expect(converter.example).to eq([1, 2, 3])
      end
    end

    context 'when no example is provided' do
      let(:options) { { type: 'String' } }

      it 'returns nil' do
        expect(converter.example).to be_nil
      end
    end

    context 'when documentation exists but no example' do
      let(:options) { { type: 'String', documentation: { desc: 'A description' } } }

      it 'returns nil' do
        expect(converter.example).to be_nil
      end
    end

    context 'when documentation is nil' do
      let(:options) { { type: 'String', documentation: nil } }

      it 'returns nil' do
        expect(converter.example).to be_nil
      end
    end

    context 'when example is an empty string' do
      let(:options) { { type: 'String', documentation: { example: '' } } }

      it 'returns empty string' do
        expect(converter.example).to eq('')
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers, RSpec/VerifiedDoubles
end
