require 'spec_helper'

describe StorageShardEntity, :postgresql do
  let(:entity) { described_class.new(StorageShard.new, request: double) }

  subject { entity.as_json }

  it { is_expected.to have_key(:name) }
end
