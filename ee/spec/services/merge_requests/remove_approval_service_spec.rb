require 'rails_helper'

describe MergeRequests::RemoveApprovalService do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:project) { create(:project, approvals_before_merge: 1) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    subject(:service) { described_class.new(project, user) }

    def execute!
      service.execute(merge_request)
    end

    context 'with a user who has approved' do
      before do
        project.add_developer(create(:user))
        merge_request.update!(approvals_before_merge: 2)
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
        expect(service).not_to receive(:notification_service)

        execute!
      end

      it 'resets the cache for approvals' do
        expect(merge_request).to receive(:reset_approval_cache!)

        execute!
      end
    end

    context 'with an approved merge request' do
      let(:notification_service) { NotificationService.new }

      before do
        merge_request.approvals.create(user: user)
        allow(service).to receive(:notification_service).and_return(notification_service)
      end

      it 'sends a notification' do
        expect(notification_service).to receive_message_chain(:async, :unapprove_mr).with(merge_request, user)

        execute!
      end
    end
  end
end
