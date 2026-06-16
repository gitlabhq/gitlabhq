# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/events/merge_requests/code_conflict_event'
require_relative '../../support/shared_examples/events/cloud_event_with_schema_shared_examples'
require_relative '../../support/shared_examples/events/merge_request_base_cloud_event_shared_examples'

RSpec.describe MergeRequests::CodeConflictEvent, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }

  describe '.build' do
    let(:event) { described_class.build(merge_request: merge_request) }

    it_behaves_like 'a merge request base cloud event'

    it 'sets event_type to :code_conflict' do
      expect(event.event_type).to eq(:code_conflict)
    end

    it 'uses the merge request author as current_user' do
      expect(event.data[:gitlab_user_id]).to eq(merge_request.author.id)
    end

    context 'when the merge request author is nil' do
      before do
        allow(merge_request).to receive(:author).and_return(nil)
      end

      it 'returns nil' do
        expect(described_class.build(merge_request: merge_request)).to be_nil
      end
    end
  end

  it_behaves_like 'a cloud event with schema',
    valid_data: {
      merge_request_id: 1,
      merge_request_iid: 10,
      project_id: 100
    },
    missing_required: %i[merge_request_id merge_request_iid project_id],
    invalid_types: {
      merge_request_id: 'not_an_integer',
      merge_request_iid: 'not_an_integer',
      project_id: 'not_an_integer'
    }
end
