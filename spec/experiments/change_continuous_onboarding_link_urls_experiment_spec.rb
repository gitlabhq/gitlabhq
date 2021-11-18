# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ChangeContinuousOnboardingLinkUrlsExperiment, :snowplow do
  before do
    stub_experiments(change_continuous_onboarding_link_urls: 'control')
  end

  describe '#track' do
    context 'when no namespace has been set' do
      it 'tracks the action as normal' do
        subject.track(:some_action)

        expect_snowplow_event(
          category: subject.name,
          action: 'some_action',
          namespace: nil,
          context: [
            {
              schema: 'iglu:com.gitlab/gitlab_experiment/jsonschema/1-0-0',
              data: an_instance_of(Hash)
            }
          ]
        )
      end
    end

    context 'when a namespace has been set' do
      let_it_be(:namespace) { create(:namespace) }

      before do
        subject.namespace = namespace
      end

      it 'tracks the action and merges the namespace into the event args' do
        subject.track(:some_action)

        expect_snowplow_event(
          category: subject.name,
          action: 'some_action',
          namespace: namespace,
          context: [
            {
              schema: 'iglu:com.gitlab/gitlab_experiment/jsonschema/1-0-0',
              data: an_instance_of(Hash)
            }
          ]
        )
      end
    end
  end
end
