# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/organizations/confirmed_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Organizations::ConfirmedEvent, feature_category: :organization do
  it_behaves_like 'an event with schema',
    valid_data: { organization_id: 1 },
    missing_required: %i[organization_id],
    invalid_types: { organization_id: 'not_an_integer' }
end
