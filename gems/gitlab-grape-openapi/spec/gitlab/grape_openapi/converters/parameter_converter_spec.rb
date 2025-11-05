# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Converters::ParameterConverter do
  let(:required) { true }
  let(:type) { 'String' }
  let(:name) { "active" }
  let(:options) { { required: required, desc: "Filter by active users", type: type } }
  let(:validations) { [] }

  subject(:parameter) do
    described_class.convert(name, options: options, validations: validations, route_path: "/api/v1/:id/:user_id")
  end

  describe '#in_value' do
    context 'when parameter is in path (GET)' do
      let(:name) { "user_id" }

      it 'returns path as the in_value' do
        expect(parameter.in_value).to eq('path')
      end
    end

    context 'when parameter is not in path (GET)' do
      let(:name) { "hello_world" }

      it 'returns path as the in_value' do
        expect(parameter.in_value).to eq('query')
      end
    end
  end

  describe '.convert' do
    it 'returns a Gitlab::GrapeOpenapi::Models::Parameter instance' do
      expect(parameter).to be_a(Gitlab::GrapeOpenapi::Models::Parameter)
    end

    it 'sets the name value correctly' do
      expect(parameter.name).to eq('active')
    end

    it 'sets the desc value correctly' do
      expect(parameter.description).to eq('Filter by active users')
    end

    context 'when required' do
      it 'sets required' do
        expect(parameter.required).to be true
      end
    end

    context 'when optional' do
      let(:required) { false }

      it 'sets optional' do
        expect(parameter.required).to be false
      end
    end

    context 'when type is String' do
      it 'sets schema type' do
        expect(parameter.schema[:type]).to eq('string')
      end
    end

    context 'when type is Boolean' do
      let(:type) { 'Grape::API::Boolean' }

      it 'sets schema type' do
        expect(parameter.schema[:type]).to eq('boolean')
      end
    end

    context 'when type is Integer' do
      let(:type) { 'integer' }

      it 'sets schema type' do
        expect(parameter.schema[:type]).to eq('integer')
      end
    end

    context 'when multiple types are allowed' do
      let(:type) { "[String, Integer]" }

      it 'sets schema type' do
        expect(parameter.schema)
          .to eq({ oneOf: [{ type: 'string' }, { type: 'integer' }] })
      end
    end

    context 'when values are defined' do
      let(:options) { { required: required, desc: "Filter by active users", type: type, values: %w[foo bar baz] } }

      it 'defines enum in output' do
        expect(parameter.schema)
          .to eq({ type: 'string', enum: %w[foo bar baz] })
      end
    end

    context 'when a default is defined' do
      let(:options) { { required: required, desc: "Filter by active users", type: type, default: 'foo' } }

      it 'returns the value within the schema' do
        expect(parameter.schema).to eq({ type: 'string', default: 'foo' })
      end
    end

    context 'when an example is defined' do
      let(:options) do
        { required: required, desc: "Filter by active users", type: type, documentation: { example: 'abcd' } }
      end

      it 'returns the value within the schema' do
        expect(parameter.example).to eq('abcd')
      end
    end

    context 'when parameter is a DateTime' do
      let(:options) do
        { required: required, desc: "Example datetime", type: 'DateTime' }
      end

      it 'returns the type' do
        expect(parameter.schema[:type]).to eq('string')
        expect(parameter.schema[:format]).to eq('date-time')
      end
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
  end
end
