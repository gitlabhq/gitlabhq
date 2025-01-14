# frozen_string_literal: true

RSpec.describe ActiveContext::Config do
  let(:logger) { ::Logger.new(nil) }
  let(:elastic) do
    {
      es1: {
        adapter: 'elasticsearch',
        prefix: 'gitlab',
        options: { elastisearch_url: 'http://localhost:9200' }
      }
    }
  end

  before do
    described_class.configure do |config|
      config.enabled = nil
    end
  end

  describe '.configure' do
    it 'creates a new instance with the provided configuration block' do
      described_class.configure do |config|
        config.enabled = true
        config.databases = elastic
        config.logger = logger
      end

      expect(described_class.enabled?).to be true
      expect(described_class.databases).to eq(elastic)
      expect(described_class.logger).to eq(logger)
    end
  end

  describe '.enabled?' do
    context 'when enabled is not set' do
      it 'returns false' do
        expect(described_class.enabled?).to be false
      end
    end

    context 'when enabled is set to true' do
      before do
        described_class.configure do |config|
          config.enabled = true
        end
      end

      it 'returns true' do
        expect(described_class.enabled?).to be true
      end
    end
  end

  describe '.databases' do
    context 'when databases are not set' do
      it 'returns an empty hash' do
        expect(described_class.databases).to eq({})
      end
    end

    context 'when databases are set' do
      before do
        described_class.configure do |config|
          config.databases = elastic
        end
      end

      it 'returns the configured databases' do
        expect(described_class.databases).to eq(elastic)
      end
    end
  end

  describe '.logger' do
    context 'when logger is not set' do
      it 'returns a default stdout logger' do
        expect(described_class.logger).to be_a(Logger)
      end
    end

    context 'when logger is set' do
      before do
        described_class.configure do |config|
          config.logger = logger
        end
      end

      it 'returns the configured logger' do
        expect(described_class.logger).to eq(logger)
      end
    end
  end
end
