require 'spec_helper'

describe StorageShard do
  describe '.all' do
    it 'returns an array of StorageShard objects' do
      shards = described_class.all

      expect(shards.count).to eq(Settings.repositories.storages.count)
      expect(shards.map(&:name)).to match_array(Settings.repositories.storages.keys)
    end
  end

  describe '.build_digest' do
    it 'returns SHA1 digest for the current configuration' do
      expect(described_class.build_digest).to eq('aea7849c10b886c202676ff34ce9fdf0940567b8')
    end
  end
end
