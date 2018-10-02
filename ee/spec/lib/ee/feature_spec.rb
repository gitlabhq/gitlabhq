# frozen_string_literal: true

require 'spec_helper'

describe Feature do
  include EE::GeoHelpers

  describe '.enable' do
    context 'when running on a Geo primary node' do
      before do
        stub_primary_node
      end

      it 'does not create a Geo::CacheInvalidationEvent if there are no Geo secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { described_class.enable(:foo) }.not_to change(Geo::CacheInvalidationEvent, :count)
      end

      it 'creates a Geo::CacheInvalidationEvent' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [double] }

        expect { described_class.enable(:foo) }.to change(Geo::CacheInvalidationEvent, :count).by(1)
      end
    end
  end

  describe '.disable' do
    context 'when running on a Geo primary node' do
      before do
        stub_primary_node
      end

      it 'does not create a Geo::CacheInvalidationEvent if there are no Geo secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { described_class.disable(:foo) }.not_to change(Geo::CacheInvalidationEvent, :count)
      end

      it 'creates a Geo::CacheInvalidationEvent' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [double] }

        expect { described_class.disable(:foo) }.to change(Geo::CacheInvalidationEvent, :count).by(1)
      end
    end
  end

  describe '.enable_group' do
    context 'when running on a Geo primary node' do
      before do
        stub_primary_node
      end

      it 'does not create a Geo::CacheInvalidationEvent if there are no Geo secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { described_class.enable_group(:foo, :bar) }.not_to change(Geo::CacheInvalidationEvent, :count)
      end

      it 'creates a Geo::CacheInvalidationEvent' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [double] }

        expect { described_class.enable_group(:foo, :bar) }.to change(Geo::CacheInvalidationEvent, :count).by(1)
      end
    end
  end

  describe '.disable_group' do
    context 'when running on a Geo primary node' do
      before do
        stub_primary_node
      end

      it 'does not create a Geo::CacheInvalidationEvent if there are no Geo secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { described_class.disable_group(:foo, :bar) }.not_to change(Geo::CacheInvalidationEvent, :count)
      end

      it 'creates a Geo::CacheInvalidationEvent' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [double] }

        expect { described_class.disable_group(:foo, :bar) }.to change(Geo::CacheInvalidationEvent, :count).by(1)
      end
    end
  end
end
