# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/ci/pipeline_created_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Ci::PipelineCreatedEvent, feature_category: :continuous_integration do
  it_behaves_like 'an event with schema',
    valid_data: { pipeline_id: 1, partition_id: 100 },
    missing_required: %i[pipeline_id partition_id],
    invalid_types: { pipeline_id: 'not_an_integer', partition_id: 'not_an_integer' }
end
