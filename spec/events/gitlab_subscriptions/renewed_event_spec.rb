# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/gitlab_subscriptions/renewed_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe GitlabSubscriptions::RenewedEvent, feature_category: :subscription_management do
  it_behaves_like 'an event with schema',
    valid_data: { namespace_id: 1 },
    missing_required: %i[namespace_id],
    invalid_types: { namespace_id: 'not_an_integer' }
end
