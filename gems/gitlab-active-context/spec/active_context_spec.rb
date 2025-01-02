# frozen_string_literal: true

RSpec.describe ActiveContext do
  it "has a version number" do
    expect(ActiveContext::VERSION).not_to be_nil
  end

  describe '.configure' do
    let(:elastic) do
      {
        es1: {
          adapter: 'elasticsearch',
          prefix: 'gitlab',
          options: { elastisearch_url: 'http://localhost:9200' }
        }
      }
    end

    it 'creates a new instance with the provided configuration block' do
      ActiveContext.configure do |config|
        config.enabled = true
        config.databases = elastic
        config.logger = ::Logger.new(nil)
      end

      expect(ActiveContext::Config.enabled?).to be true
      expect(ActiveContext::Config.databases).to eq(elastic)
      expect(ActiveContext::Config.logger).to be_a(::Logger)
    end
  end

  describe '.config' do
    it 'returns the current configuration' do
      config = described_class.config
      expect(config).to be_a(ActiveContext::Config::Cfg)
    end
  end

  describe '.adapter' do
    it 'returns nil when not configured' do
      expect(described_class.adapter).to be_nil
    end

    it 'returns configured adapter' do
      described_class.configure do |config|
        config.enabled = true
        config.databases = {
          main: {
            adapter: 'ActiveContext::Databases::Postgresql::Adapter',
            options: {
              host: 'localhost',
              port: 5432,
              database: 'test_db'
            }
          }
        }
      end

      expect(described_class.adapter).to be_a(ActiveContext::Databases::Postgresql::Adapter)
    end
  end
end
