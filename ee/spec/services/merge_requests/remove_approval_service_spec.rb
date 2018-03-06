require 'rails_helper'

describe MergeRequests::RemoveApprovalService do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:merge_request) { create(:merge_request) }
    let(:project) { merge_request.project }

    subject(:service) { described_class.new(project, user) }

    def execute!
      service.execute(merge_request)
    end

    context 'with a user who has approved' do
      before do
        merge_request.approvals.create(user: user)
      end

      it 'removes the approval' do
        expect(merge_request.approvals.size).to eq 1
        execute!
        expect(merge_request.approvals).to be_empty
      end

      it 'creates an unapproval note' do
        expect(SystemNoteService).to receive(:unapprove_mr)

        execute!
      end

      it 'does not send a notification' do
        expect(Notify).not_to receive(:unapprove_mr)

        execute!
      end

      it 'resets the cache for approvals' do
        expect(merge_request).to receive(:reset_approval_cache!)

        execute!
      end
    end

    context 'with an approved merge request' do
      let(:notify) { Object.new }

      before do
        merge_request.update_attribute :approvals_before_merge, 1
        merge_request.approvals.create(user: user)
        allow(service).to receive(:notification_service).and_return(notify)
      end

      it 'sends a notification' do
        expect(notify).to receive(:unapprove_mr)
        execute!
      end
    end
  end
end
