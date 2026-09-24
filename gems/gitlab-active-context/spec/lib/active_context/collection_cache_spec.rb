# frozen_string_literal: true

RSpec.describe ActiveContext::CollectionCache do
  describe '.reset' do
    it 'clears the cached collections and refresh timestamp' do
      described_class.instance_variable_set(:@collections, { 1 => double('Collection') })
      described_class.instance_variable_set(:@last_refreshed_at, Time.current)

      described_class.reset

      expect(described_class.instance_variable_get(:@collections)).to be_nil
      expect(described_class.instance_variable_get(:@last_refreshed_at)).to be_nil
    end
  end
end
