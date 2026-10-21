# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/events/merge_requests/requested_changes_cloud_event'
require_relative '../../support/shared_examples/events/cloud_event_with_schema_shared_examples'
require_relative '../../support/shared_examples/events/merge_request_base_cloud_event_shared_examples'

RSpec.describe MergeRequests::RequestedChangesCloudEvent, feature_category: :dap_triggers do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }

  describe '.build' do
    let(:review_workflow_id) { nil }
    let(:event) do
      described_class.build(
        merge_request: merge_request, current_user: user, review_workflow_id: review_workflow_id
      )
    end

    it_behaves_like 'a merge request base cloud event'

    it 'sets event_type to :requested_changes' do
      expect(event.event_type).to eq(:requested_changes)
    end

    it 'omits review_workflow_id' do
      expect(event.event_data).not_to have_key(:review_workflow_id)
    end

    context 'with a review workflow' do
      let(:review_workflow_id) { non_existing_record_id }

      it 'includes review_workflow_id' do
        expect(event.event_data[:review_workflow_id]).to eq(review_workflow_id)
      end
    end
  end

  it_behaves_like 'a cloud event with schema',
    valid_data: {
      merge_request_id: 1,
      merge_request_iid: 10,
      project_id: 100,
      review_workflow_id: 5
    },
    missing_required: %i[merge_request_id merge_request_iid project_id],
    invalid_types: {
      merge_request_id: 'not_an_integer',
      merge_request_iid: 'not_an_integer',
      project_id: 'not_an_integer',
      review_workflow_id: 'not_an_integer'
    }
end
