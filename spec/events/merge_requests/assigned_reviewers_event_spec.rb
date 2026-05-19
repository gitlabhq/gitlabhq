# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/events/merge_requests/assigned_reviewers_event'
require_relative '../../support/shared_examples/events/cloud_event_with_schema_shared_examples'

RSpec.describe MergeRequests::AssignedReviewersEvent, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:reviewer1) { create(:user) }
  let_it_be(:reviewer2) { create(:user) }

  describe '.build' do
    it 'returns a valid AssignedReviewerEvent' do
      event = described_class.build(
        current_user: user, merge_request: merge_request, new_reviewers: [reviewer1, reviewer2]
      )
      expect(event.event_category).to eq(:merge_requests)
      expect(event.event_type).to eq(:assigned_reviewers)
    end
  end

  it_behaves_like 'a cloud event with schema',
    valid_data: {
      merge_request_id: 1,
      merge_request_iid: 10,
      project_id: 100,
      new_reviewers: [{ id: 1, user_type: "human" }]
    },
    missing_required: %i[merge_request_id merge_request_iid project_id new_reviewers],
    invalid_types: {
      merge_request_id: 'not_an_integer',
      merge_request_iid: 'not_an_integer',
      project_id: 'not_an_integer',
      new_reviewers: 'not_an_array'
    }
end
