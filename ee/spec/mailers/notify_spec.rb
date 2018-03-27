require 'spec_helper'
require 'email_spec'

describe Notify do
  include EmailSpec::Helpers
  include EmailSpec::Matchers
  include RepoHelpers

  include_context 'gitlab email notification'

  set(:user) { create(:user) }
  set(:current_user) { create(:user, email: "current@email.com") }
  set(:assignee) { create(:user, email: 'assignee@example.com', name: 'John Doe') }

  set(:merge_request) do
    create(:merge_request, source_project: project,
                           target_project: project,
                           author: current_user,
                           assignee: assignee,
                           description: 'Awesome description')
  end

  set(:project2) { create(:project, :repository) }
  set(:merge_request_without_assignee) do
    create(:merge_request, source_project: project2,
                           author: current_user,
                           description: 'Awesome description')
  end

  context 'for a project' do
    context 'for merge requests' do
      describe "that are new with approver" do
        before do
          create(:approver, target: merge_request)
        end

        subject do
          described_class.new_merge_request_email(
            merge_request.assignee_id, merge_request.id
          )
        end

        it "contains the approvers list" do
          is_expected.to have_body_text /#{merge_request.approvers.first.user.name}/
        end
      end

      describe 'that are approved' do
        let(:last_approver) { create(:user) }
        subject { described_class.approved_merge_request_email(recipient.id, merge_request.id, last_approver.id) }

        before do
          merge_request.approvals.create(user: merge_request.assignee)
          merge_request.approvals.create(user: last_approver)
        end

        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end
        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'

        it 'is sent as the last approver' do
          sender = subject.header[:from].addrs[0]
          expect(sender.display_name).to eq(last_approver.name)
          expect(sender.address).to eq(gitlab_sender)
        end

        it 'has the correct subject' do
          is_expected.to have_subject /#{merge_request.title} \(#{merge_request.to_reference}\)/
        end

        it 'contains the new status' do
          is_expected.to have_body_text /approved/i
        end

        it 'contains a link to the merge request' do
          is_expected.to have_body_text /#{project_merge_request_path project, merge_request}/
        end

        it 'contains the names of all of the approvers' do
          is_expected.to have_body_text /#{merge_request.assignee.name}/
          is_expected.to have_body_text /#{last_approver.name}/
        end

        context 'when merge request has no assignee' do
          before do
            merge_request.update(assignee: nil)
          end

          it 'does not show the assignee' do
            is_expected.not_to have_body_text 'Assignee'
          end
        end
      end

      describe 'that are unapproved' do
        let(:last_unapprover) { create(:user) }
        subject { described_class.unapproved_merge_request_email(recipient.id, merge_request.id, last_unapprover.id) }

        before do
          merge_request.approvals.create(user: merge_request.assignee)
        end

        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end
        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'

        it 'is sent as the last unapprover' do
          sender = subject.header[:from].addrs[0]
          expect(sender.display_name).to eq(last_unapprover.name)
          expect(sender.address).to eq(gitlab_sender)
        end

        it 'has the correct subject' do
          is_expected.to have_subject /#{merge_request.title} \(#{merge_request.to_reference}\)/
        end

        it 'contains the new status' do
          is_expected.to have_body_text /unapproved/i
        end

        it 'contains a link to the merge request' do
          is_expected.to have_body_text /#{project_merge_request_path project, merge_request}/
        end

        it 'contains the names of all of the approvers' do
          is_expected.to have_body_text /#{merge_request.assignee.name}/
        end
      end
    end

    context 'for merge requests without assignee' do
      describe 'that are unapproved' do
        let(:last_unapprover) { create(:user) }
        subject { described_class.unapproved_merge_request_email(recipient.id, merge_request_without_assignee.id, last_unapprover.id) }

        before do
          merge_request_without_assignee.approvals.create(user: merge_request_without_assignee.assignee)
        end

        it 'contains the new status' do
          is_expected.to have_body_text /unapproved/i
        end
      end
    end
  end
end
