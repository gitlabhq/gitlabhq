require 'spec_helper'

describe Approvable do
  let(:merge_request) { create(:merge_request) }

  describe '#approvers_overwritten?' do
    subject { merge_request.approvers_overwritten? }

    it 'returns false when merge request has no approvers' do
      is_expected.to be false
    end

    it 'returns true when merge request has user approver' do
      create(:approver, target: merge_request)

      is_expected.to be true
    end

    it 'returns true when merge request has group approver' do
      group = create(:group_with_members)
      create(:approver_group, target: merge_request, group: group)

      is_expected.to be true
    end
  end
end
