require 'spec_helper'

describe Approvable do
  let(:merge_request) { create(:merge_request, :with_approver) }

  describe '#approvers_left' do
    it 'only queries once' do
      merge_request

      expect(User).to receive(:where).and_call_original.once

      3.times { merge_request.approvers_left }
    end
  end

  describe '#reset_approval_cache!' do
    it 'clears the cache of approvers left' do
      user_can_approve = merge_request.approvers_left.first
      merge_request.approvals.create!(user: user_can_approve)

      merge_request.reset_approval_cache!

      expect(merge_request.approvers_left).to be_empty
    end
  end
end
