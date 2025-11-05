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

      it 'maps symbol to string' do
        expect(described_class.resolve_type('symbol')).to eq('string')
      end

      it 'maps String to string' do
        expect(described_class.resolve_type('String')).to eq('string')
      end

      it 'maps text to string' do
        expect(described_class.resolve_type('text')).to eq('string')
      end
    end

    context 'with class type mappings' do
      it 'maps String class to string' do
        expect(described_class.resolve_type(String)).to eq('string')
      end

      it 'maps Integer class to integer' do
        expect(described_class.resolve_type(Integer)).to eq('integer')
      end
    end

    context 'with integer type mappings' do
      it 'maps Integer to integer' do
        expect(described_class.resolve_type('Integer')).to eq('integer')
      end

      it 'maps :int symbol to integer' do
        expect(described_class.resolve_type(:int)).to eq('integer')
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

      it 'returns the original type for unknown class' do
        expect(described_class.resolve_type(Array)).to eq(Array)
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

      it 'maps date type to date format' do
        expect(described_class.resolve_format(nil, 'date')).to eq('date')
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

  describe 'constants' do
    describe 'TYPE_MAPPINGS' do
      it 'is frozen' do
        expect(described_class::TYPE_MAPPINGS).to be_frozen
      end

      it 'contains expected mappings' do
        expected_mappings = {
          'dateTime' => 'string',
          'date' => 'string',
          'symbol' => 'string',
          'String' => 'string',
          String => 'string',
          'Integer' => 'integer',
          Integer => 'integer',
          :int => 'integer',
          'text' => 'string',
          'Hash' => 'object',
          'hash' => 'object',
          'JSON' => 'object',
          :hash => 'object',
          "Grape::API::Boolean" => 'boolean'
        }

        expect(described_class::TYPE_MAPPINGS).to eq(expected_mappings)
      end
    end

    describe 'FORMAT_MAPPINGS' do
      it 'is frozen' do
        expect(described_class::FORMAT_MAPPINGS).to be_frozen
      end

      it 'contains expected mappings' do
        expected_mappings = {
          'dateTime' => 'date-time',
          'date' => 'date'
        }

        expect(described_class::FORMAT_MAPPINGS).to eq(expected_mappings)
      end
    end
  end
end
