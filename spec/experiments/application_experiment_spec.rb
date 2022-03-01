# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationExperiment, :experiment do
  subject(:application_experiment) { described_class.new('namespaced/stub', **context) }

  let(:context) { {} }
  let(:feature_definition) { { name: 'namespaced_stub', type: 'experiment', default_enabled: false } }

  around do |example|
    Feature::Definition.definitions[:namespaced_stub] = Feature::Definition.new('namespaced_stub.yml', feature_definition)
    example.run
    Feature::Definition.definitions.delete(:namespaced_stub)
  end

  before do
    allow(application_experiment).to receive(:enabled?).and_return(true)
  end

  it "registers a default control behavior for anonymous experiments" do
    # This default control behavior is not inherited, intentionally, but it
    # does provide anonymous experiments with a base control behavior to keep
    # them optional there.

    expect(experiment(:example)).to register_behavior(:control).with(nil)
    expect { experiment(:example) { } }.not_to raise_error
  end

  describe "#publish" do
    it "tracks the assignment", :snowplow do
      expect(application_experiment).to receive(:track).with(:assignment)

      application_experiment.publish
    end

    it "adds to the published experiments" do
      # These are surfaced in the client layer by rendering them in the
      # _published_experiments.html.haml partial.
      application_experiment.publish

      expect(ApplicationExperiment.published_experiments['namespaced/stub']).to include(
        experiment: 'namespaced/stub',
        excluded: false,
        key: anything,
        variant: 'control'
      )
    end

    describe '#publish_to_database' do
      using RSpec::Parameterized::TableSyntax

      let(:publish_to_database) { ActiveSupport::Deprecation.silence { application_experiment.publish_to_database } }

      shared_examples 'does not record to the database' do
        it 'does not create an experiment record' do
          expect { publish_to_database }.not_to change(Experiment, :count)
        end

        it 'does not create an experiment subject record' do
          expect { publish_to_database }.not_to change(ExperimentSubject, :count)
        end
      end

      context 'when there is a usable subject' do
        let(:context) { { context_key => context_value } }

        where(:context_key, :context_value, :object_type) do
          :namespace | build(:namespace, id: non_existing_record_id) | :namespace
          :group     | build(:namespace, id: non_existing_record_id) | :namespace
          :project   | build(:project, id: non_existing_record_id)   | :project
          :user      | build(:user, id: non_existing_record_id)      | :user
          :actor     | build(:user, id: non_existing_record_id)      | :user
        end

        with_them do
          it 'creates an experiment and experiment subject record' do
            expect { publish_to_database }.to change(Experiment, :count).by(1)

            expect(Experiment.last.name).to eq('namespaced/stub')
            expect(ExperimentSubject.last.send(object_type)).to eq(context[context_key])
          end
        end
      end

      context "when experiment hasn't ran" do
        let(:context) { { user: create(:user) } }

        it 'sets a variant on the experiment subject' do
          publish_to_database

          expect(ExperimentSubject.last.variant).to eq('control')
        end
      end

      context 'when there is not a usable subject' do
        let(:context) { { context_key => context_value } }

        where(:context_key, :context_value) do
          :namespace | nil
          :foo       | :bar
        end

        with_them do
          include_examples 'does not record to the database'
        end
      end

      context 'but we should not track' do
        let(:should_track) { false }

        include_examples 'does not record to the database'
      end
    end
  end

  describe "#track", :snowplow do
    let(:fake_context) do
      SnowplowTracker::SelfDescribingJson.new('iglu:com.gitlab/fake/jsonschema/0-0-0', { data: '_data_' })
    end

    it "doesn't track if we shouldn't track" do
      allow(application_experiment).to receive(:should_track?).and_return(false)

      application_experiment.track(:action)

      expect_no_snowplow_event
    end

    it "tracks the event with the expected arguments and merged contexts" do
      application_experiment.track(:action, property: '_property_', context: [fake_context])

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

    context "when using known context resources" do
      let(:user) { build(:user, id: non_existing_record_id) }
      let(:project) { build(:project, id: non_existing_record_id) }
      let(:namespace) { build(:namespace, id: non_existing_record_id) }
      let(:group) { build(:group, id: non_existing_record_id) }
      let(:actor) { user }

      let(:context) { { user: user, project: project, namespace: namespace } }

      it "includes those using the gitlab standard context" do
        subject.track(:action)

        expect_snowplow_event(
          category: 'namespaced/stub',
          action: 'action',
          user: user,
          project: project,
          namespace: namespace,
          context: an_instance_of(Array)
        )
      end

      it "falls back to using the group key" do
        subject.context(namespace: nil, group: group)

        subject.track(:action)

        expect_snowplow_event(
          category: 'namespaced/stub',
          action: 'action',
          user: user,
          project: project,
          namespace: group,
          context: an_instance_of(Array)
        )
      end

      context "with the actor key" do
        it "provides it to the tracking call as the user" do
          subject.context(user: nil, actor: actor)

          subject.track(:action)

          expect_snowplow_event(
            category: 'namespaced/stub',
            action: 'action',
            user: actor,
            project: project,
            namespace: namespace,
            context: an_instance_of(Array)
          )
        end

        it "handles when it's not a user record" do
          subject.context(user: nil, actor: nil)

          subject.track(:action)

          expect_snowplow_event(
            category: 'namespaced/stub',
            action: 'action',
            project: project,
            namespace: namespace,
            context: an_instance_of(Array)
          )
        end
      end
    end
  end

  describe "#key_for" do
    it "generates MD5 hashes" do
      expect(application_experiment.key_for(foo: :bar)).to eq('6f9ac12afdb9b58c2f19a136d09f9153')
    end
  end

  describe "#process_redirect_url" do
    using RSpec::Parameterized::TableSyntax

    where(:url, :processed_url) do
      'https://about.gitlab.com/'                 | 'https://about.gitlab.com/'
      'https://gitlab.com/'                       | 'https://gitlab.com/'
      'http://docs.gitlab.com'                    | 'http://docs.gitlab.com'
      'https://docs.gitlab.com/some/path?foo=bar' | 'https://docs.gitlab.com/some/path?foo=bar'
      'http://badgitlab.com'                      | nil
      'https://gitlab.com.nefarious.net'          | nil
      'https://unknown.gitlab.com'                | nil
      "https://badplace.com\nhttps://gitlab.com"  | nil
      'https://gitlabbcom'                        | nil
      'https://gitlabbcom/'                       | nil
      'http://gdk.test/foo/bar'                   | 'http://gdk.test/foo/bar'
      'http://localhost:3000/foo/bar'             | 'http://localhost:3000/foo/bar'
    end

    with_them do
      it "returns the url or nil if invalid" do
        allow(Gitlab).to receive(:dev_env_or_com?).and_return(true)
        expect(application_experiment.process_redirect_url(url)).to eq(processed_url)
      end

      it "considers all urls invalid when not on dev or com" do
        allow(Gitlab).to receive(:dev_env_or_com?).and_return(false)
        expect(application_experiment.process_redirect_url(url)).to be_nil
      end
    end

    it "generates the correct urls based on where the engine was mounted" do
      url = Rails.application.routes.url_helpers.experiment_redirect_url(application_experiment, url: 'https://docs.gitlab.com')
      expect(url).to include("/-/experiment/namespaced%2Fstub:#{application_experiment.context.key}?https://docs.gitlab.com")
    end
  end

  context "when resolving variants" do
    before do
      stub_feature_flags(namespaced_stub: true)
    end

    it "returns an assigned name" do
      application_experiment.variant(:variant1) {}
      application_experiment.variant(:variant2) {}

      expect(application_experiment.assigned.name).to eq('variant2')
    end
  end

  context "when nesting experiments" do
    before do
      stub_experiments(top: :control, nested: :control)
    end

    it "doesn't raise an exception" do
      expect { experiment(:top) { |e| e.control { experiment(:nested) { } } } }.not_to raise_error
    end

    it "tracks an event", :snowplow do
      experiment(:top) { |e| e.control { experiment(:nested) { } } }

      expect(Gitlab::Tracking).to have_received(:event).with( # rubocop:disable RSpec/ExpectGitlabTracking
        'top',
        'nested',
        hash_including(label: 'nested')
      )
    end
  end

  context "when caching" do
    let(:cache) { Gitlab::Experiment::Configuration.cache }

    before do
      allow(Gitlab::Experiment::Configuration).to receive(:cache).and_call_original

      cache.clear(key: application_experiment.name)

      application_experiment.control { }
      application_experiment.candidate { }
    end

    it "caches the variant determined by the variant resolver" do
      expect(application_experiment.variant.name).to eq('candidate') # we should be in the experiment

      application_experiment.run

      expect(application_experiment.cache.read).to eq('candidate')
    end

    it "doesn't cache a variant if we don't explicitly provide one" do
      # by not caching "empty" variants, we effectively create a mostly
      # optimal combination of caching and rollout flexibility. If we cached
      # every control variant assigned, we'd inflate the cache size and
      # wouldn't be able to roll out to subjects that we'd already assigned to
      # the control.
      stub_feature_flags(namespaced_stub: false) # simulate being not rolled out

      expect(application_experiment.variant.name).to eq('control') # if we ask, it should be control

      application_experiment.run

      expect(application_experiment.cache.read).to be_nil
    end

    it "caches a control variant if we assign it specifically" do
      # by specifically assigning the control variant here, we're guaranteeing
      # that this context will always get the control variant unless we delete
      # the field from the cache (or clear the entire experiment cache) -- or
      # write code that would specify a different variant.
      application_experiment.run(:control)

      expect(application_experiment.cache.read).to eq('control')
    end

    context "arbitrary attributes" do
      before do
        application_experiment.cache.store.clear(key: application_experiment.name + '_attrs')
      end

      it "sets and gets attributes about an experiment" do
        application_experiment.cache.attr_set(:foo, :bar)

        expect(application_experiment.cache.attr_get(:foo)).to eq('bar')
      end

      it "increments a value for an experiment" do
        expect(application_experiment.cache.attr_get(:foo)).to be_nil

        expect(application_experiment.cache.attr_inc(:foo)).to eq(1)
        expect(application_experiment.cache.attr_inc(:foo)).to eq(2)
      end
    end
  end

  context "with deprecation warnings" do
    before do
      Gitlab::Experiment::Configuration.instance_variable_set(:@__dep_versions, nil) # clear the internal memoization

      allow(ActiveSupport::Deprecation).to receive(:new).and_call_original
    end

    it "doesn't warn on non dev/test environments" do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)

      expect { experiment(:example) { |e| e.use { } } }.not_to raise_error
      expect(ActiveSupport::Deprecation).not_to have_received(:new).with(anything, 'Gitlab::Experiment')
    end

    it "warns on dev and test environments" do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(true)

      # This will eventually raise an ActiveSupport::Deprecation exception,
      # it's ok to change it when that happens.
      expect { experiment(:example) { |e| e.use { } } }.not_to raise_error

      expect(ActiveSupport::Deprecation).to have_received(:new).with(anything, 'Gitlab::Experiment')
    end
  end
end
