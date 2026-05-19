# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../app/events/ci/workloads/workload_finished_event'
require_relative '../../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Ci::Workloads::WorkloadFinishedEvent, feature_category: :continuous_integration do
  it_behaves_like 'an event with schema',
    valid_data: { workload_id: 1, status: 'success' },
    missing_required: %i[workload_id status],
    invalid_types: { workload_id: 'not_an_integer', status: 123 }
end
