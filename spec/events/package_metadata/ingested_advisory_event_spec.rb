# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/package_metadata/ingested_advisory_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe PackageMetadata::IngestedAdvisoryEvent, feature_category: :software_composition_analysis do
  it_behaves_like 'an event with schema',
    valid_data: { advisory_id: 1 },
    missing_required: %i[advisory_id],
    invalid_types: { advisory_id: 'not_an_integer' }
end
