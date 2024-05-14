# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Metadata::Deserializer do
  subject(:deserializer) { described_class }

  describe '.parse_value' do
    context 'when type is :string' do
      it 'delegates to parse_string' do
        expect(deserializer).to receive(:parse_string).with('content')

        deserializer.parse_value(type: :string, value: 'content')
      end
    end

    context 'when type is :time' do
      it 'delegates to parse_time' do
        encoded_time = '2024-05-05T00:00:00Z'

        expect(deserializer).to receive(:parse_time).with(encoded_time)

        deserializer.parse_value(type: :time, value: encoded_time)
      end
    end

    context 'when type is :integer' do
      it 'delegates to parse_integer' do
        expect(deserializer).to receive(:parse_integer).with(1)

        deserializer.parse_value(type: :integer, value: 1)
      end
    end

    context 'when type is something else' do
      it 'raises an error' do
        expect { deserializer.parse_value(type: :something, value: '123') }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.parse_string' do
    it 'returns a string' do
      expect(deserializer.parse_string('content')).to eq('content')
      expect(deserializer.parse_string(123)).to eq('123')
      expect(deserializer.parse_string('')).to eq('')
      expect(deserializer.parse_string(nil)).to eq('')
    end
  end

  describe '.parse_time' do
    context 'with a valid time' do
      it 'returns a Time object' do
        encoded_time = '2024-05-05T00:00:00Z'
        expected_time = Time.new(2024, 5, 5, 0, 0, 0, '+00:00')

        parsed_time = deserializer.parse_time(encoded_time)
        expect(parsed_time).to be_a(Time)
        expect(parsed_time).to eq(expected_time)
      end
    end

    context 'with an invalid time' do
      it 'returns nil' do
        expect { deserializer.parse_time('invalid') }.not_to raise_error
        expect(deserializer.parse_time('invalid')).to be_nil
      end
    end
  end

  describe '.parse_integer' do
    context 'with a non empty value' do
      it 'returns an integer' do
        expect(deserializer.parse_integer('123')).to eq(123)
        expect(deserializer.parse_integer(123)).to eq(123)
        expect(deserializer.parse_integer('')).to eq(0)
      end
    end

    context 'with an null value' do
      it 'returns nil' do
        expect(deserializer.parse_integer(nil)).to be_nil
      end
    end
  end
end
