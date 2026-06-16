# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/members/accepted_invite_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Members::AcceptedInviteEvent, feature_category: :seat_cost_management do
  it_behaves_like 'an event with schema',
    valid_data: { source_id: 1, source_type: 'Project', user_id: 2, member_id: 3 },
    missing_required: %i[source_id source_type user_id member_id],
    invalid_types: {
      source_id: 'not_an_integer',
      source_type: 123,
      user_id: 'not_an_integer',
      member_id: 'not_an_integer'
    }
end
