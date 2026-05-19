# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/users/activity_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Users::ActivityEvent, feature_category: :seat_cost_management do
  it_behaves_like 'an event with schema',
    valid_data: { user_id: 1, namespace_id: 2 },
    missing_required: %i[user_id namespace_id],
    invalid_types: { user_id: 'not_an_integer', namespace_id: 'not_an_integer' }
end
