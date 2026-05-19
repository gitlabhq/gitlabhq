# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/merge_requests/merge_request_prepared_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe MergeRequests::MergeRequestPreparedEvent, feature_category: :code_review_workflow do
  it_behaves_like 'an event with schema',
    valid_data: {
      project_id: 1,
      user_id: 2,
      oldrev: 'abc123',
      newrev: 'def456',
      ref: 'refs/heads/main'
    },
    missing_required: %i[project_id user_id oldrev newrev ref],
    invalid_types: { project_id: 'not_an_integer', oldrev: 123 }
end
