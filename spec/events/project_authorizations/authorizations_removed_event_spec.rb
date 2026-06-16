# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/project_authorizations/authorizations_removed_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe ProjectAuthorizations::AuthorizationsRemovedEvent, feature_category: :permissions do
  it_behaves_like 'an event with schema',
    valid_data: { project_id: 1, user_ids: [2, 3] },
    missing_required: %i[project_id user_ids],
    invalid_types: { project_id: 'not_an_integer', user_ids: 'not_an_array' }
end
