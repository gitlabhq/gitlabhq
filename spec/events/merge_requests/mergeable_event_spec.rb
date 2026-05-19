# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/merge_requests/mergeable_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe MergeRequests::MergeableEvent, feature_category: :code_review_workflow do
  it_behaves_like 'an event with schema',
    valid_data: { merge_request_id: 1 },
    missing_required: %i[merge_request_id],
    invalid_types: { merge_request_id: 'not_an_integer' }
end
