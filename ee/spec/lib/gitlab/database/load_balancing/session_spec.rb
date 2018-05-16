require 'spec_helper'

describe Gitlab::Database::LoadBalancing::Session do
  after do
    described_class.clear_session
  end

  describe '.current' do
    it 'returns the current session' do
      expect(described_class.current).to be_an_instance_of(described_class)
    end
  end

  describe '.clear_session' do
    it 'clears the current session' do
      described_class.current
      described_class.clear_session

      expect(RequestStore[described_class::CACHE_KEY]).to be_nil
    end
  end

  describe '#use_primary?' do
    it 'returns true when the primary should be used' do
      instance = described_class.new

      instance.use_primary!

      expect(instance.use_primary?).to eq(true)
    end

    it 'returns false when a secondary should be used' do
      expect(described_class.new.use_primary?).to eq(false)
    end

    it 'returns true when a write was performed' do
      instance = described_class.new

      instance.write!

      expect(instance.use_primary?).to eq(true)
    end
  end

  describe '#performed_write?' do
    it 'returns true if a write was performed' do
      instance = described_class.new

      instance.write!

      expect(instance.performed_write?).to eq(true)
    end
  end

  describe '#reset!' do
    it 'switches the session back to read from a secondary' do
      instance = described_class.new

      instance.use_primary!
      instance.last_write_location = 'foo'
      instance.reset!

      expect(instance.use_primary?).to eq(false)
      expect(instance.last_write_location).to be_nil
    end
  end

  describe 'transaction nesting' do
    it 'supports tracking of transaction states' do
      instance = described_class.new

      expect(instance).not_to be_in_transaction

      instance.enter_transaction

      expect(instance).to be_in_transaction

      instance.leave_transaction

      expect(instance).not_to be_in_transaction
    end
  end
end
