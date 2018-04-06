require 'spec_helper'

describe Gitlab::Chat, :use_clean_rails_memory_store_caching do
  describe '.available?' do
    it 'returns true when the chatops feature is available' do
      allow(License)
        .to receive(:feature_available?)
        .with(:chatops)
        .and_return(true)

      expect(described_class).to be_available
    end

    it 'returns false when the chatops feature is not available' do
      allow(License)
        .to receive(:feature_available?)
        .with(:chatops)
        .and_return(false)

      expect(described_class).not_to be_available
    end

    it 'caches the feature availability' do
      expect(License)
        .to receive(:feature_available?)
        .once
        .with(:chatops)
        .and_return(true)

      2.times do
        described_class.available?
      end
    end
  end

  describe '.flush_available_cache' do
    it 'flushes the feature availability cache' do
      expect(License)
        .to receive(:feature_available?)
        .twice
        .with(:chatops)
        .and_return(true)

      described_class.available?
      described_class.flush_available_cache
      described_class.available?
    end
  end
end
