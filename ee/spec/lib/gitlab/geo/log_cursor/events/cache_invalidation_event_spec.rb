# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Geo::LogCursor::Events::CacheInvalidationEvent, :postgresql, :clean_gitlab_redis_shared_state do
  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:event_log) { create(:geo_event_log, :cache_invalidation_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
  let(:cache_invalidation_event) { event_log.cache_invalidation_event }
  let(:cache_key) { cache_invalidation_event.key }

  subject { described_class.new(cache_invalidation_event, Time.now, logger) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  describe '#process' do
    it 'expires the cache of the given key' do
      expect(Rails.cache).to receive(:delete).with(cache_key).and_call_original

      subject.process
    end

    it 'logs an info event' do
      data = {
        class: described_class.name,
        message: 'Cache invalidation',
        cache_key: cache_key,
        cache_expired: false,
        skippable: false
      }

      expect(::Gitlab::Logger)
        .to receive(:info)
        .with(hash_including(data))

      subject.process
    end
  end
end
