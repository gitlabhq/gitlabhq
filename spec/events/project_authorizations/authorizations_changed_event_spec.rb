# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/project_authorizations/authorizations_changed_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe ProjectAuthorizations::AuthorizationsChangedEvent, feature_category: :permissions do
  it_behaves_like 'an event with schema',
    valid_data: { project_id: 1 },
    missing_required: %i[project_id],
    invalid_types: { project_id: 'not_an_integer' }
end
