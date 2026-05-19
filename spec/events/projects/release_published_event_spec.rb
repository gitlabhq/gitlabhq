# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/projects/release_published_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Projects::ReleasePublishedEvent, feature_category: :release_orchestration do
  it_behaves_like 'an event with schema',
    valid_data: { release_id: 1 },
    missing_required: %i[release_id],
    invalid_types: { release_id: 'not_an_integer' }
end
