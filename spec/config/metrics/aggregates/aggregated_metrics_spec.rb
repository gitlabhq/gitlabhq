# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'aggregated metrics' do
  RSpec::Matchers.define :be_known_event do
    match do |event|
      Gitlab::UsageDataCounters::HLLRedisCounter.known_event?(event)
    end

    failure_message do |event|
      "Event with name: `#{event}` can not be found within `#{Gitlab::UsageDataCounters::HLLRedisCounter::KNOWN_EVENTS_PATH}`"
    end
  end

  RSpec::Matchers.define :has_known_source do
    match do |aggregate|
      Gitlab::Usage::Metrics::Aggregates::SOURCES.include?(aggregate[:source])
    end

    failure_message do |aggregate|
      "Aggregate with name: `#{aggregate[:name]}` uses not allowed source `#{aggregate[:source]}`"
    end
  end

  RSpec::Matchers.define :have_known_time_frame do
    allowed_time_frames = [
      Gitlab::Usage::TimeFrame::ALL_TIME_TIME_FRAME_NAME,
      Gitlab::Usage::TimeFrame::TWENTY_EIGHT_DAYS_TIME_FRAME_NAME,
      Gitlab::Usage::TimeFrame::SEVEN_DAYS_TIME_FRAME_NAME
    ]

    match do |aggregate|
      (aggregate[:time_frame] - allowed_time_frames).empty?
    end

    failure_message do |aggregate|
      "Aggregate with name: `#{aggregate[:name]}` uses not allowed time_frame`#{aggregate[:time_frame] - allowed_time_frames}`"
    end
  end

  let_it_be(:known_events) do
    Gitlab::UsageDataCounters::HLLRedisCounter.known_events
  end

  Gitlab::Usage::Metrics::Aggregates::Aggregate.new(Time.current).send(:aggregated_metrics).tap do |aggregated_metrics|
    it 'all events has unique name' do
      event_names = aggregated_metrics&.map { |event| event[:name] }

      expect(event_names).to eq(event_names&.uniq)
    end

    it 'all aggregated metrics has known source' do
      expect(aggregated_metrics).to all has_known_source
    end

    it 'all aggregated metrics has known source' do
      expect(aggregated_metrics).to all have_known_time_frame
    end

    aggregated_metrics&.select { |agg| agg[:source] == Gitlab::Usage::Metrics::Aggregates::REDIS_SOURCE }&.each do |aggregate|
      context "for #{aggregate[:name]} aggregate of #{aggregate[:events].join(' ')}" do
        let_it_be(:events_records) { known_events.select { |event| aggregate[:events].include?(event[:name]) } }

        it "does not include 'all' time frame for Redis sourced aggregate" do
          expect(aggregate[:time_frame]).not_to include(Gitlab::Usage::TimeFrame::ALL_TIME_TIME_FRAME_NAME)
        end

        it "only refers to known events" do
          expect(aggregate[:events]).to all be_known_event
        end

        it "has expected structure" do
          expect(aggregate.keys).to include(*%w[name operator events])
        end

        it "uses allowed aggregation operators" do
          expect(Gitlab::Usage::Metrics::Aggregates::ALLOWED_METRICS_AGGREGATIONS).to include aggregate[:operator]
        end

        it "uses events from the same Redis slot" do
          event_slots = events_records.map { |event| event[:redis_slot] }.uniq

          expect(event_slots).to contain_exactly(be_present)
        end

        it "uses events with the same aggregation period" do
          event_slots = events_records.map { |event| event[:aggregation] }.uniq

          expect(event_slots).to contain_exactly(be_present)
        end
      end
    end
  end
end
