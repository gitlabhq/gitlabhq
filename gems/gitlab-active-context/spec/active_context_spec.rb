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
end
