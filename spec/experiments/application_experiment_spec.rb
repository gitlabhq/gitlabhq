# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationExperiment, :experiment do
  subject { described_class.new(:stub) }

  before do
    allow(subject).to receive(:enabled?).and_return(true)
  end

  it "naively assumes a 1x1 relationship to feature flags for tests" do
    expect(Feature).to receive(:persist_used!).with('stub')

    described_class.new(:stub)
  end

  describe "enabled" do
    before do
      allow(subject).to receive(:enabled?).and_call_original

      allow(Feature::Definition).to receive(:get).and_return('_instance_')
      allow(Gitlab).to receive(:dev_env_or_com?).and_return(true)
      allow(Feature).to receive(:get).and_return(double(state: :on))
    end

    it "is enabled when all criteria are met" do
      expect(subject).to be_enabled
    end

    it "isn't enabled if the feature definition doesn't exist" do
      expect(Feature::Definition).to receive(:get).with('stub').and_return(nil)

      expect(subject).not_to be_enabled
    end

    it "isn't enabled if we're not in dev or dotcom environments" do
      expect(Gitlab).to receive(:dev_env_or_com?).and_return(false)

      expect(subject).not_to be_enabled
    end

    it "isn't enabled if the feature flag state is :off" do
      expect(Feature).to receive(:get).with('stub').and_return(double(state: :off))

      expect(subject).not_to be_enabled
    end
  end

  describe "publishing results" do
    it "tracks the assignment" do
      expect(subject).to receive(:track).with(:assignment)

      subject.publish(nil)
    end

    it "pushes the experiment knowledge into the client using Gon.global" do
      expect(Gon.global).to receive(:push).with(
        {
          experiment: {
            'stub' => { # string key because it can be namespaced
              experiment: 'stub',
              key: 'e8f65fd8d973f9985dc7ea3cf1614ae1',
              variant: 'control'
            }
          }
        },
        true
      )

      subject.publish(nil)
    end
  end

  describe "tracking events", :snowplow do
    it "doesn't track if we shouldn't track" do
      allow(subject).to receive(:should_track?).and_return(false)

      subject.track(:action)

      expect_no_snowplow_event
    end

    it "tracks the event with the expected arguments and merged contexts" do
      subject.track(:action, property: '_property_', context: [
        SnowplowTracker::SelfDescribingJson.new('iglu:com.gitlab/fake/jsonschema/0-0-0', { data: '_data_' })
      ])

      expect_snowplow_event(
        category: 'stub',
        action: 'action',
        property: '_property_',
        context: [
          {
            schema: 'iglu:com.gitlab/fake/jsonschema/0-0-0',
            data: { data: '_data_' }
          },
          {
            schema: 'iglu:com.gitlab/gitlab_experiment/jsonschema/0-3-0',
            data: { experiment: 'stub', key: 'e8f65fd8d973f9985dc7ea3cf1614ae1', variant: 'control' }
          }
        ]
      )
    end
  end

  describe "variant resolution" do
    it "returns nil when not rolled out" do
      stub_feature_flags(stub: false)

      expect(subject.variant.name).to eq('control')
    end

    context "when rolled out to 100%" do
      it "returns the first variant name" do
        subject.try(:variant1) {}
        subject.try(:variant2) {}

        expect(subject.variant.name).to eq('variant1')
      end
    end
  end

  context "when caching" do
    let(:cache) { ApplicationExperiment::Cache.new }

    before do
      cache.clear(key: subject.name)

      subject.use { } # setup the control
      subject.try { } # setup the candidate

      allow(Gitlab::Experiment::Configuration).to receive(:cache).and_return(cache)
    end

    it "caches the variant determined by the variant resolver" do
      expect(subject.variant.name).to eq('candidate') # we should be in the experiment

      subject.run

      expect(cache.read(subject.cache_key)).to eq('candidate')
    end

    it "doesn't cache a variant if we don't explicitly provide one" do
      # by not caching "empty" variants, we effectively create a mostly
      # optimal combination of caching and rollout flexibility. If we cached
      # every control variant assigned, we'd inflate the cache size and
      # wouldn't be able to roll out to subjects that we'd already assigned to
      # the control.
      stub_feature_flags(stub: false) # simulate being not rolled out

      expect(subject.variant.name).to eq('control') # if we ask, it should be control

      subject.run

      expect(cache.read(subject.cache_key)).to be_nil
    end

    it "caches a control variant if we assign it specifically" do
      # by specifically assigning the control variant here, we're guaranteeing
      # that this context will always get the control variant unless we delete
      # the field from the cache (or clear the entire experiment cache) -- or
      # write code that would specify a different variant.
      subject.run(:control)

      expect(cache.read(subject.cache_key)).to eq('control')
    end
  end
end
