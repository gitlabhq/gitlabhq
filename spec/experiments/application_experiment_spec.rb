# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationExperiment, :experiment do
  subject { described_class.new('namespaced/stub', **context) }

  let(:context) { {} }
  let(:feature_definition) { { name: 'namespaced_stub', type: 'experiment', default_enabled: false } }

  around do |example|
    Feature::Definition.definitions[:namespaced_stub] = Feature::Definition.new('namespaced_stub.yml', feature_definition)
    example.run
    Feature::Definition.definitions.delete(:namespaced_stub)
  end

  before do
    allow(subject).to receive(:enabled?).and_return(true)
  end

  it "doesn't raise an exception without a defined control" do
    # because we have a default behavior defined

    expect { experiment('namespaced/stub') { } }.not_to raise_error
  end

  describe "#enabled?" do
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
      expect(Feature::Definition).to receive(:get).with('namespaced_stub').and_return(nil)

      expect(subject).not_to be_enabled
    end

    it "isn't enabled if we're not in dev or dotcom environments" do
      expect(Gitlab).to receive(:dev_env_or_com?).and_return(false)

      expect(subject).not_to be_enabled
    end

    it "isn't enabled if the feature flag state is :off" do
      expect(Feature).to receive(:get).with('namespaced_stub').and_return(double(state: :off))

      expect(subject).not_to be_enabled
    end
  end

  describe "#publish" do
    it "doesn't track or publish to the client or database if we can't track", :snowplow do
      allow(subject).to receive(:should_track?).and_return(false)

      expect(subject).not_to receive(:publish_to_client)
      expect(subject).not_to receive(:publish_to_database)

      subject.publish

      expect_no_snowplow_event
    end

    it "tracks the assignment" do
      expect(subject).to receive(:track).with(:assignment)

      subject.publish
    end

    it "publishes the to the client" do
      expect(subject).to receive(:publish_to_client)

      subject.publish
    end

    it "publishes to the database if we've opted for that" do
      subject.record!

      expect(subject).to receive(:publish_to_database)

      subject.publish
    end

    describe "#publish_to_client" do
      it "adds the data into Gon" do
        signature = { key: '86208ac54ca798e11f127e8b23ec396a', variant: 'control' }
        expect(Gon).to receive(:push).with({ experiment: { 'namespaced/stub' => hash_including(signature) } }, true)

        subject.publish_to_client
      end

      it "handles when Gon raises exceptions (like when it can't be pushed into)" do
        expect(Gon).to receive(:push).and_raise(NoMethodError)

        expect { subject.publish_to_client }.not_to raise_error
      end
    end

    describe "#publish_to_database" do
      using RSpec::Parameterized::TableSyntax
      let(:context) { { context_key => context_value }}

      before do
        subject.record!
      end

      context "when there's a usable subject" do
        where(:context_key, :context_value, :object_type) do
          :namespace | build(:namespace) | :namespace
          :group     | build(:namespace) | :namespace
          :project   | build(:project)   | :project
          :user      | build(:user)      | :user
          :actor     | build(:user)      | :user
        end

        with_them do
          it "creates an experiment and experiment subject record" do
            expect { subject.publish_to_database }.to change(Experiment, :count).by(1)

            expect(Experiment.last.name).to eq('namespaced/stub')
            expect(ExperimentSubject.last.send(object_type)).to eq(context[context_key])
          end
        end
      end

      context "when there's not a usable subject" do
        where(:context_key, :context_value) do
          :namespace | nil
          :foo       | :bar
        end

        with_them do
          it "doesn't create an experiment record" do
            expect { subject.publish_to_database }.not_to change(Experiment, :count)
          end

          it "doesn't create an experiment subject record" do
            expect { subject.publish_to_database }.not_to change(ExperimentSubject, :count)
          end
        end
      end
    end
  end

  describe "#track", :snowplow do
    let(:fake_context) do
      SnowplowTracker::SelfDescribingJson.new('iglu:com.gitlab/fake/jsonschema/0-0-0', { data: '_data_' })
    end

    it "doesn't track if we shouldn't track" do
      allow(subject).to receive(:should_track?).and_return(false)

      subject.track(:action)

      expect_no_snowplow_event
    end

    it "tracks the event with the expected arguments and merged contexts" do
      subject.track(:action, property: '_property_', context: [fake_context])

      expect_snowplow_event(
        category: 'namespaced/stub',
        action: 'action',
        property: '_property_',
        context: [
          {
            schema: 'iglu:com.gitlab/fake/jsonschema/0-0-0',
            data: { data: '_data_' }
          },
          {
            schema: 'iglu:com.gitlab/gitlab_experiment/jsonschema/1-0-0',
            data: { experiment: 'namespaced/stub', key: '86208ac54ca798e11f127e8b23ec396a', variant: 'control' }
          }
        ]
      )
    end

    it "tracks the event correctly even when using the base class" do
      subject = Gitlab::Experiment.new(:unnamed)
      subject.track(:action, context: [fake_context])

      expect_snowplow_event(
        category: 'unnamed',
        action: 'action',
        context: [
          {
            schema: 'iglu:com.gitlab/fake/jsonschema/0-0-0',
            data: { data: '_data_' }
          },
          {
            schema: 'iglu:com.gitlab/gitlab_experiment/jsonschema/1-0-0',
            data: { experiment: 'unnamed', key: subject.context.key, variant: 'control' }
          }
        ]
      )
    end
  end

  describe "#key_for" do
    it "generates MD5 hashes" do
      expect(subject.key_for(foo: :bar)).to eq('6f9ac12afdb9b58c2f19a136d09f9153')
    end
  end

  context "when resolving variants" do
    it "uses the default value as specified in the yaml" do
      expect(Feature).to receive(:enabled?).with('namespaced_stub', subject, type: :experiment, default_enabled: :yaml)

      expect(subject.variant.name).to eq('control')
    end

    context "when rolled out to 100%" do
      before do
        stub_feature_flags(namespaced_stub: true)
      end

      it "returns the first variant name" do
        subject.try(:variant1) {}
        subject.try(:variant2) {}

        expect(subject.variant.name).to eq('variant1')
      end
    end
  end

  context "when caching" do
    let(:cache) { Gitlab::Experiment::Configuration.cache }

    before do
      allow(Gitlab::Experiment::Configuration).to receive(:cache).and_call_original

      cache.clear(key: subject.name)

      subject.use { } # setup the control
      subject.try { } # setup the candidate
    end

    it "caches the variant determined by the variant resolver" do
      expect(subject.variant.name).to eq('candidate') # we should be in the experiment

      subject.run

      expect(subject.cache.read).to eq('candidate')
    end

    it "doesn't cache a variant if we don't explicitly provide one" do
      # by not caching "empty" variants, we effectively create a mostly
      # optimal combination of caching and rollout flexibility. If we cached
      # every control variant assigned, we'd inflate the cache size and
      # wouldn't be able to roll out to subjects that we'd already assigned to
      # the control.
      stub_feature_flags(namespaced_stub: false) # simulate being not rolled out

      expect(subject.variant.name).to eq('control') # if we ask, it should be control

      subject.run

      expect(subject.cache.read).to be_nil
    end

    it "caches a control variant if we assign it specifically" do
      # by specifically assigning the control variant here, we're guaranteeing
      # that this context will always get the control variant unless we delete
      # the field from the cache (or clear the entire experiment cache) -- or
      # write code that would specify a different variant.
      subject.run(:control)

      expect(subject.cache.read).to eq('control')
    end

    context "arbitrary attributes" do
      before do
        subject.cache.store.clear(key: subject.name + '_attrs')
      end

      it "sets and gets attributes about an experiment" do
        subject.cache.attr_set(:foo, :bar)

        expect(subject.cache.attr_get(:foo)).to eq('bar')
      end

      it "increments a value for an experiment" do
        expect(subject.cache.attr_get(:foo)).to be_nil

        expect(subject.cache.attr_inc(:foo)).to eq(1)
        expect(subject.cache.attr_inc(:foo)).to eq(2)
      end
    end
  end
end
