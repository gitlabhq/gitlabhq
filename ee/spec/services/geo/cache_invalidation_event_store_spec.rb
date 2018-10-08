# frozen_string_literal: true

require 'spec_helper'

describe Geo::CacheInvalidationEventStore do
  include EE::GeoHelpers

  set(:secondary_node) { create(:geo_node) }

  let(:cache_key) { 'cache-key' }

  subject { described_class.new(cache_key) }

  describe '#create' do
    it_behaves_like 'a Geo event store', Geo::CacheInvalidationEvent

    context 'when running on a primary node' do
      before do
        stub_primary_node
      end

      it 'tracks the cache key that should be invalidated' do
        subject.create!

        expect(Geo::CacheInvalidationEvent.last).to have_attributes(key: cache_key)
      end

      it 'logs an error message when event creation fail' do
        subject = described_class.new(nil)

        expected_message = {
          class: described_class.name,
          cache_key: '',
          message: 'Cache invalidation event could not be created',
          error: "Validation failed: Key can't be blank"
        }

        expect(Gitlab::Geo::Logger).to receive(:error)
          .with(expected_message).and_call_original

        subject.create!
      end
    end
  end
end
