# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Converters::TypeResolver do
  describe '.resolve_type' do
    context 'with string type mappings' do
      it 'maps dateTime to string' do
        expect(described_class.resolve_type('dateTime')).to eq('string')
      end

      it 'maps date to string' do
        expect(described_class.resolve_type('date')).to eq('string')
      end

      it 'maps Date to string' do
        expect(described_class.resolve_type('Date')).to eq('string')
      end

      it 'maps DateTime to string' do
        expect(described_class.resolve_type('DateTime')).to eq('string')
      end

      it 'maps date-time to string' do
        expect(described_class.resolve_type('date-time')).to eq('string')
      end

      it 'maps Time to string' do
        expect(described_class.resolve_type('Time')).to eq('string')
      end

      it 'maps symbol to string' do
        expect(described_class.resolve_type('symbol')).to eq('string')
      end

      it 'maps Symbol to string' do
        expect(described_class.resolve_type('Symbol')).to eq('string')
      end

      it 'maps String to string' do
        expect(described_class.resolve_type('String')).to eq('string')
      end

      it 'maps text to string' do
        expect(described_class.resolve_type('text')).to eq('string')
      end

      it 'maps Gitlab::Color to string' do
        expect(described_class.resolve_type('Gitlab::Color')).to eq('string')
      end

      it 'maps File to string' do
        expect(described_class.resolve_type('File')).to eq('string')
      end

      it 'maps API::Validations::Types::WorkhorseFile to string' do
        expect(described_class.resolve_type('API::Validations::Types::WorkhorseFile')).to eq('string')
      end
    end

    context 'with boolean type mappings' do
      it 'maps Boolean to boolean' do
        expect(described_class.resolve_type('Boolean')).to eq('boolean')
      end

      it 'maps Grape::API::Boolean to boolean' do
        expect(described_class.resolve_type('Grape::API::Boolean')).to eq('boolean')
      end

      it 'maps TrueClass to boolean' do
        expect(described_class.resolve_type('TrueClass')).to eq('boolean')
      end

      it 'maps FalseClass to boolean' do
        expect(described_class.resolve_type('FalseClass')).to eq('boolean')
      end
    end

    context 'with class type mappings' do
      it 'maps String class to string' do
        expect(described_class.resolve_type(String)).to eq('string')
      end

      it 'maps Integer class to integer' do
        expect(described_class.resolve_type(Integer)).to eq('integer')
      end

      it 'maps Float class to number' do
        expect(described_class.resolve_type(Float)).to eq('number')
      end
    end

    context 'with integer type mappings' do
      it 'maps Integer to integer' do
        expect(described_class.resolve_type('Integer')).to eq('integer')
      end

      it 'maps :int symbol to integer' do
        expect(described_class.resolve_type(:int)).to eq('integer')
      end

      it 'maps int string to integer' do
        expect(described_class.resolve_type('int')).to eq('integer')
      end
    end

    context 'with number type mappings' do
      it 'maps Float to number' do
        expect(described_class.resolve_type('Float')).to eq('number')
      end

      it 'maps BigDecimal to number' do
        expect(described_class.resolve_type('BigDecimal')).to eq('number')
      end

      it 'maps Numeric to number' do
        expect(described_class.resolve_type('Numeric')).to eq('number')
      end
    end

    context 'with object type mappings' do
      it 'maps Hash to object' do
        expect(described_class.resolve_type('Hash')).to eq('object')
      end

      it 'maps hash to object' do
        expect(described_class.resolve_type('hash')).to eq('object')
      end

      it 'maps JSON to object' do
        expect(described_class.resolve_type('JSON')).to eq('object')
      end

      it 'maps :hash symbol to object' do
        expect(described_class.resolve_type(:hash)).to eq('object')
      end
    end

    context 'with array type mappings' do
      it 'maps Array to array' do
        expect(described_class.resolve_type('Array')).to eq('array')
      end
    end

    context 'with API:: prefixed types' do
      it 'maps unknown API:: types to object' do
        expect(described_class.resolve_type('API::Entities::Ci::PipelineBasic')).to eq('object')
      end
    end

    context 'with unmapped types' do
      it 'returns the original type when no mapping exists' do
        expect(described_class.resolve_type('boolean')).to eq('boolean')
      end

      it 'returns the original type for nil' do
        expect(described_class.resolve_type(nil)).to be_nil
      end

      it 'returns the original type for unknown string' do
        expect(described_class.resolve_type('unknown_type')).to eq('unknown_type')
      end

      it 'returns the original type for unknown symbol' do
        expect(described_class.resolve_type(:unknown)).to eq(:unknown)
      end
    end
  end

  describe '.resolve_format' do
    context 'when format is provided' do
      it 'returns the provided format over type mapping' do
        expect(described_class.resolve_format('custom-format', 'dateTime')).to eq('custom-format')
      end

      it 'returns the provided format even for unmapped types' do
        expect(described_class.resolve_format('custom-format', 'unknown')).to eq('custom-format')
      end

      it 'returns empty string when format is empty string' do
        expect(described_class.resolve_format('', 'dateTime')).to eq('')
      end
    end

    context 'when format is not provided' do
      it 'maps dateTime type to date-time format' do
        expect(described_class.resolve_format(nil, 'dateTime')).to eq('date-time')
      end

      it 'maps DateTime type to date-time format' do
        expect(described_class.resolve_format(nil, 'DateTime')).to eq('date-time')
      end

      it 'maps date type to date format' do
        expect(described_class.resolve_format(nil, 'date')).to eq('date')
      end

      it 'maps Date type to date format' do
        expect(described_class.resolve_format(nil, 'Date')).to eq('date')
      end

      it 'maps Time type to date-time format' do
        expect(described_class.resolve_format(nil, 'Time')).to eq('date-time')
      end

      it 'maps File type to binary format' do
        expect(described_class.resolve_format(nil, 'File')).to eq('binary')
      end

      it 'maps WorkhorseFile type to binary format' do
        expect(described_class.resolve_format(nil, 'API::Validations::Types::WorkhorseFile')).to eq('binary')
      end

      it 'returns nil for unmapped types' do
        expect(described_class.resolve_format(nil, 'string')).to be_nil
      end

      it 'returns nil for unknown types' do
        expect(described_class.resolve_format(nil, 'unknown')).to be_nil
      end

      it 'returns nil when both format and type are nil' do
        expect(described_class.resolve_format(nil, nil)).to be_nil
      end
    end
  end

  describe '.resolve_union_member' do
    context 'with simple types' do
      it 'returns type hash for string' do
        expect(described_class.resolve_union_member('String')).to eq({ type: 'string' })
      end

      it 'returns type hash for integer' do
        expect(described_class.resolve_union_member('Integer')).to eq({ type: 'integer' })
      end
    end

    context 'with array notation types' do
      it 'returns array schema for [Integer]' do
        expect(described_class.resolve_union_member('[Integer]')).to eq({
          type: 'array', items: { type: 'integer' }
        })
      end

      it 'returns array schema for [String]' do
        expect(described_class.resolve_union_member('[String]')).to eq({
          type: 'array', items: { type: 'string' }
        })
      end
    end

    context 'with unmapped types' do
      it 'falls back to string' do
        expect(described_class.resolve_union_member('UnknownThing')).to eq({ type: 'UnknownThing' })
      end
    end
  end

  describe 'constants' do
    describe 'TYPE_MAPPINGS' do
      it 'is frozen' do
        expect(described_class::TYPE_MAPPINGS).to be_frozen
      end

      it 'contains all expected mappings' do
        expect(described_class::TYPE_MAPPINGS).to include(
          'Boolean' => 'boolean',
          'Grape::API::Boolean' => 'boolean',
          'TrueClass' => 'boolean',
          'FalseClass' => 'boolean',
          'DateTime' => 'string',
          'dateTime' => 'string',
          'date-time' => 'string',
          'date' => 'string',
          'Date' => 'string',
          'Time' => 'string',
          'symbol' => 'string',
          'Symbol' => 'string',
          'String' => 'string',
          String => 'string',
          'Gitlab::Color' => 'string',
          'Integer' => 'integer',
          Integer => 'integer',
          :int => 'integer',
          'int' => 'integer',
          'text' => 'string',
          'Float' => 'number',
          Float => 'number',
          'BigDecimal' => 'number',
          'Numeric' => 'number',
          'Hash' => 'object',
          'hash' => 'object',
          'JSON' => 'object',
          :hash => 'object',
          'Array' => 'array',
          'File' => 'string',
          'API::Validations::Types::WorkhorseFile' => 'string'
        )
      end
    end

    describe 'FORMAT_MAPPINGS' do
      it 'is frozen' do
        expect(described_class::FORMAT_MAPPINGS).to be_frozen
      end

      it 'contains all expected mappings' do
        expect(described_class::FORMAT_MAPPINGS).to include(
          'DateTime' => 'date-time',
          'dateTime' => 'date-time',
          'date-time' => 'date-time',
          'date' => 'date',
          'Date' => 'date',
          'Time' => 'date-time',
          'File' => 'binary',
          'API::Validations::Types::WorkhorseFile' => 'binary'
        )
      end
    end
  end
end
