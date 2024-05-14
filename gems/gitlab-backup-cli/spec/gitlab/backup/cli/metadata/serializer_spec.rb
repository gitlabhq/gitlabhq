# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Metadata::Serializer do
  subject(:serializer) { described_class }

  describe '.serialize_value' do
    context 'when type is :integer' do
      it 'delegates to .serialize_integer' do
        expect(serializer).to receive(:serialize_integer).with(123)

        serializer.serialize_value(type: :integer, value: 123)
      end
    end

    context 'when type is :string' do
      it 'delegates to .serialize_string' do
        expect(serializer).to receive(:serialize_string).with('content')

        serializer.serialize_value(type: :string, value: 'content')
      end
    end

    context 'when type is :time' do
      it 'delegates to .serialize_time' do
        time = Time.now

        expect(serializer).to receive(:serialize_time).with(time)
        serializer.serialize_value(type: :time, value: time)
      end
    end

    context 'when type is something else' do
      it 'raises an error' do
        expect { serializer.serialize_value(type: :something, value: '123') }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.serialize_integer' do
    context 'when value is not nil' do
      it 'returns an integer' do
        expect(serializer.serialize_integer(123)).to eq(123)
        expect(serializer.serialize_integer('123')).to eq(123)
      end
    end

    context 'when value is nil' do
      it 'returns nil' do
        expect(serializer.serialize_integer(nil)).to be_nil
      end
    end
  end

  describe '.serialize_string' do
    it 'returns an string' do
      expect(serializer.serialize_string(123)).to eq('123')
      expect(serializer.serialize_string('content')).to eq('content')
      expect(serializer.serialize_string(nil)).to eq('')
    end
  end

  describe '.serialize_time' do
    context 'when value is a Time' do
      it 'returns a string in ISO8601 format' do
        time = Time.new(2024, 1, 1, 0, 0, 0, 'UTC')

        expect(serializer.serialize_time(time)).to eq('2024-01-01T00:00:00Z')
      end
    end

    context 'when value is nil' do
      it 'returns nil' do
        expect(serializer.serialize_time(nil)).to be_nil
      end
    end

    context 'when value is not a Time' do
      it 'raises an error' do
        expect { serializer.serialize_time('not a Time') }.to raise_error(ArgumentError)
      end
    end
  end
end
