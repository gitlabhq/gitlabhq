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

  context 'for a group' do
    describe 'for epics' do
      set(:group) { create(:group) }
      set(:epic) { create(:epic, group: group) }

      context 'that are new' do
        subject { described_class.new_epic_email(recipient.id, epic.id) }

        it_behaves_like 'an epic email starting a new thread with reply-by-email enabled' do
          let(:model) { epic }
        end
        it_behaves_like 'it should show Gmail Actions View Epic link'
        it_behaves_like 'an unsubscribeable thread'

        it 'has the correct subject and body' do
          prefix = "#{epic.group.name} | "
          suffix = "#{epic.title} (#{epic.to_reference})"

          aggregate_failures do
            is_expected.to have_subject [prefix, suffix].compact.join
            is_expected.to have_body_text(group_epic_path(group, epic))
          end
        end

        context 'got deleted before notification' do
          subject { described_class.new_epic_email(recipient.id, 0) }

          it 'does not send email' do
            expect(subject.message).to be_a_kind_of ActionMailer::Base::NullMail
          end
        end
      end

      context 'for epic notes' do
        set(:note) { create(:note, project: nil, noteable: epic) }
        let(:note_author) { note.author }
        let(:epic_note_path) { group_epic_path(group, epic, anchor: "note_#{note.id}") }

        subject { described_class.note_epic_email(recipient.id, note.id) }

        it_behaves_like 'a note email'

        it_behaves_like 'an unsubscribeable thread'

        it 'has the characteristics of a threaded reply' do
          host = Gitlab.config.gitlab.host
          route_key = "#{epic.class.model_name.singular_route_key}_#{epic.id}"

          aggregate_failures do
            is_expected.to have_header('Message-ID', /\A<.*@#{host}>\Z/)
            is_expected.to have_header('In-Reply-To', "<#{route_key}@#{host}>")
            is_expected.to have_header('References',  /\A<reply\-.*@#{host}> <#{route_key}@#{host}>\Z/ )
            is_expected.to have_subject(/^Re: /)
          end
        end

        context 'when reply-by-email is enabled with incoming address with %{key}' do
          it 'has a Reply-To header' do
            is_expected.to have_header 'Reply-To', /<reply+(.*)@#{Gitlab.config.gitlab.host}>\Z/
          end
        end

        it_behaves_like 'it should show Gmail Actions View Epic link'

        it 'has the correct subject and body' do
          prefix = "Re: #{epic.group.name} | "
          suffix = "#{epic.title} (#{epic.to_reference})"

          aggregate_failures do
            is_expected.to have_subject [prefix, suffix].compact.join
            is_expected.to have_body_text(epic_note_path)
          end
        end
      end
    end
  end

  describe 'mirror was hard failed' do
    let(:project) { create(:project, :mirror, :import_hard_failed) }

    subject { described_class.mirror_was_hard_failed_email(project.id, user.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like "a user cannot unsubscribe through footer link"

    it 'has the correct subject and body' do
      is_expected.to have_subject("#{project.name} | Repository mirroring paused")
      is_expected.to have_body_text(project.full_path)
      is_expected.to have_body_text(project_settings_repository_url(project))
    end
  end

  describe 'mirror user changed' do
    let(:mirror_user) { create(:user) }
    let(:project) { create(:project, :mirror, mirror_user_id: mirror_user.id) }
    let(:new_mirror_user) { project.team.owners.first }

    subject { described_class.project_mirror_user_changed_email(new_mirror_user.id, mirror_user.name, project.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like "a user cannot unsubscribe through footer link"

    it 'has the correct subject and body' do
      is_expected.to have_subject("#{project.name} | Mirror user changed")
      is_expected.to have_body_text(project.full_path)
    end
  end

  describe 'admin notification' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }

    subject { @email = described_class.send_admin_notification(user.id, 'Admin announcement', 'Text') }

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq("GitLab")
      expect(sender.address).to eq(gitlab_sender)
    end

    it 'is sent to recipient' do
      is_expected.to deliver_to user.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject 'Admin announcement'
    end

    it 'includes unsubscribe link' do
      unsubscribe_link = "http://localhost/unsubscribes/#{Base64.urlsafe_encode64(user.email)}"
      is_expected.to have_body_text(unsubscribe_link)
    end
  end
end
