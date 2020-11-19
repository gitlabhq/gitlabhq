# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ByApprovalsFinder do
  let_it_be(:first_user) { create(:user) }
  let_it_be(:second_user) { create(:user) }
  let(:third_user) { create(:user) }

  let_it_be(:merge_request_without_approvals) { create(:merge_request) }
  let_it_be(:merge_request_with_first_user_approval) do
    create(:merge_request).tap do |mr|
      create(:approval, merge_request: mr, user: first_user)
    end
  end

  let_it_be(:merge_request_with_both_approvals) do
    create(:merge_request).tap do |mr|
      create(:approval, merge_request: mr, user: first_user)
      create(:approval, merge_request: mr, user: second_user)
    end
  end

  def merge_requests(ids: nil, names: [])
    described_class.new(names, ids).execute(MergeRequest.all)
  end

  context 'filter by no approvals' do
    it 'returns merge requests without approvals' do
      expected_result = [merge_request_without_approvals]

      expect(merge_requests(ids: 'None')).to match_array(expected_result)
      expect(merge_requests(names: ['None'])).to match_array(expected_result)
    end
  end

  context 'filter by any approvals' do
    it 'returns merge requests approved by at least one user' do
      expected_result = [merge_request_with_first_user_approval, merge_request_with_both_approvals]

      expect(merge_requests(ids: 'Any')).to match_array(expected_result)
      expect(merge_requests(names: ['Any'])).to match_array(expected_result)
    end
  end

  context 'filter by specific user approval' do
    it 'returns merge requests approved by specific user' do
      expected_result = [merge_request_with_first_user_approval, merge_request_with_both_approvals]

      expect(merge_requests(ids: [first_user.id])).to match_array(expected_result)
      expect(merge_requests(names: [first_user.username])).to match_array(expected_result)
    end
  end

  context 'filter by multiple user approval' do
    it 'returns merge requests approved by both users' do
      expected_result = [merge_request_with_both_approvals]

      expect(merge_requests(ids: [first_user.id, second_user.id])).to match_array(expected_result)
      expect(merge_requests(names: [first_user.username, second_user.username])).to match_array(expected_result)
    end

    context 'limiting max conditional elements' do
      it 'returns merge requests approved by both users, considering limit of 2 being defined' do
        stub_const('MergeRequests::ByApprovalsFinder::MAX_FILTER_ELEMENTS', 2)

        expected_result = [merge_request_with_both_approvals]

        expect(merge_requests(ids: [first_user.id, second_user.id, third_user.id])).to match_array(expected_result)
        expect(merge_requests(names: [first_user.username, second_user.username, third_user.username])).to match_array(expected_result)
      end
    end
  end

  context 'with empty params' do
    it 'returns all merge requests' do
      expected_result = [merge_request_without_approvals, merge_request_with_first_user_approval, merge_request_with_both_approvals]

      expect(merge_requests(ids: [])).to match_array(expected_result)
      expect(merge_requests(names: [])).to match_array(expected_result)
    end
  end
end
