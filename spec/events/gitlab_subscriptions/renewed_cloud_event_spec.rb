# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/gitlab_subscriptions/renewed_cloud_event'
require_relative '../../support/shared_examples/events/cloud_event_with_schema_shared_examples'

RSpec.describe GitlabSubscriptions::RenewedCloudEvent, feature_category: :subscription_management do
  # rubocop:disable RSpec/VerifiedDoubles -- GitlabSubscription is not loadable under fast_spec_helper
  let(:subscription) { double(id: 7, namespace_id: 42) }
  # rubocop:enable RSpec/VerifiedDoubles

  describe '.build' do
    it 'builds a valid cloud event for the subscription', :aggregate_failures do
      event = described_class.build(subscription: subscription)

      expect(event.event_category).to eq(:gitlab_subscriptions)
      expect(event.event_type).to eq(:renewed)
      expect(event.data[:source]).to eq('namespaces/42')
      expect(event.data[:subject]).to eq('gitlab_subscriptions/7')
      expect(event.event_data).to eq(namespace_id: 42)
    end

    it 'omits the user and organization envelope attributes', :aggregate_failures do
      event = described_class.build(subscription: subscription)

      expect(event.data).not_to have_key(:gitlab_user_id)
      expect(event.data).not_to have_key(:gitlab_organization_id)
    end
  end

  it_behaves_like 'a cloud event with schema',
    valid_data: { namespace_id: 1 },
    missing_required: %i[namespace_id],
    invalid_types: { namespace_id: 'not_an_integer' }

  describe '#data_schema' do
    it 'rejects unexpected properties' do
      event = described_class.build(subscription: subscription)
      invalid_data = event.data.merge(data: event.event_data.merge(unexpected: 'data'))

      expect { described_class.new(data: invalid_data) }
        .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
    end
  end
end
