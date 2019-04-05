require 'rails_helper'

describe 'Issues > User uses quick actions', :js do
  include Spec::Support::Helpers::Features::NotesHelpers

  context "issuable common quick actions" do
    let(:new_url_opts) { {} }
    let(:maintainer) { create(:user) }
    let(:project) { create(:project, :public) }
    let!(:label_bug) { create(:label, project: project, title: 'bug') }
    let!(:label_feature) { create(:label, project: project, title: 'feature') }
    let!(:milestone) { create(:milestone, project: project, title: 'ASAP') }
    let(:issuable) { create(:issue, project: project) }
    let(:source_issuable) { create(:issue, project: project, milestone: milestone, labels: [label_bug, label_feature])}

    it_behaves_like 'assign quick action', :issue
    it_behaves_like 'unassign quick action', :issue
    it_behaves_like 'close quick action', :issue
    it_behaves_like 'reopen quick action', :issue
    it_behaves_like 'title quick action', :issue
    it_behaves_like 'todo quick action', :issue
    it_behaves_like 'done quick action', :issue
    it_behaves_like 'subscribe quick action', :issue
    it_behaves_like 'unsubscribe quick action', :issue
    it_behaves_like 'lock quick action', :issue
    it_behaves_like 'unlock quick action', :issue
    it_behaves_like 'milestone quick action', :issue
    it_behaves_like 'remove_milestone quick action', :issue
    it_behaves_like 'label quick action', :issue
    it_behaves_like 'unlabel quick action', :issue
    it_behaves_like 'relabel quick action', :issue
    it_behaves_like 'award quick action', :issue
    it_behaves_like 'estimate quick action', :issue
    it_behaves_like 'remove_estimate quick action', :issue
    it_behaves_like 'spend quick action', :issue
    it_behaves_like 'remove_time_spent quick action', :issue
    it_behaves_like 'shrug quick action', :issue
    it_behaves_like 'tableflip quick action', :issue
    it_behaves_like 'copy_metadata quick action', :issue
    it_behaves_like 'issuable time tracker', :issue
  end

  describe 'issue-only commands' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public) }
    let(:issue) { create(:issue, project: project, due_date: Date.new(2016, 8, 28)) }

    before do
      project.add_maintainer(user)
      sign_in(user)
      visit project_issue_path(project, issue)
      wait_for_all_requests
    end

    after do
      wait_for_requests
    end

    it_behaves_like 'confidential quick action'
    it_behaves_like 'remove_due_date quick action'

    describe 'adding a due date from note' do
      let(:issue) { create(:issue, project: project) }

      it_behaves_like 'due quick action available and date can be added'

      context 'when the current user cannot update the due date' do
        let(:guest) { create(:user) }
        before do
          project.add_guest(guest)
          gitlab_sign_out
          sign_in(guest)
          visit project_issue_path(project, issue)
        end

        it_behaves_like 'due quick action not available'
      end
    end

    describe 'toggling the WIP prefix from the title from note' do
      let(:issue) { create(:issue, project: project) }

      it 'does not recognize the command nor create a note' do
        add_note("/wip")

        expect(page).not_to have_content '/wip'
      end
    end

    describe 'mark issue as duplicate' do
      let(:issue) { create(:issue, project: project) }
      let(:original_issue) { create(:issue, project: project) }

      context 'when the current user can update issues' do
        it 'does not create a note, and marks the issue as a duplicate' do
          add_note("/duplicate ##{original_issue.to_reference}")

          expect(page).not_to have_content "/duplicate #{original_issue.to_reference}"
          expect(page).to have_content 'Commands applied'
          expect(page).to have_content "marked this issue as a duplicate of #{original_issue.to_reference}"

          expect(issue.reload).to be_closed
        end
      end

      context 'when the current user cannot update the issue' do
        let(:guest) { create(:user) }
        before do
          project.add_guest(guest)
          gitlab_sign_out
          sign_in(guest)
          visit project_issue_path(project, issue)
        end

        it 'does not create a note, and does not mark the issue as a duplicate' do
          add_note("/duplicate ##{original_issue.to_reference}")

          expect(page).not_to have_content 'Commands applied'
          expect(page).not_to have_content "marked this issue as a duplicate of #{original_issue.to_reference}"

          expect(issue.reload).to be_open
        end
      end
    end

    describe 'move the issue to another project' do
      let(:issue) { create(:issue, project: project) }

      context 'when the project is valid' do
        let(:target_project) { create(:project, :public) }

        before do
          target_project.add_maintainer(user)
          gitlab_sign_out
          sign_in(user)
          visit project_issue_path(project, issue)
          wait_for_requests
        end

        it 'moves the issue' do
          add_note("/move #{target_project.full_path}")

          expect(page).to have_content 'Commands applied'
          expect(issue.reload).to be_closed

          visit project_issue_path(target_project, issue)

          expect(page).to have_content 'Issues 1'
        end
      end

      context 'when the project is valid but the user not authorized' do
        let(:project_unauthorized) { create(:project, :public) }

        before do
          gitlab_sign_out
          sign_in(user)
          visit project_issue_path(project, issue)
          wait_for_requests
        end

        it 'does not move the issue' do
          add_note("/move #{project_unauthorized.full_path}")

          wait_for_requests

          expect(page).to have_content 'Commands applied'
          expect(issue.reload).to be_open
        end
      end

      context 'when the project is invalid' do
        before do
          gitlab_sign_out
          sign_in(user)
          visit project_issue_path(project, issue)
          wait_for_requests
        end

        it 'does not move the issue' do
          add_note("/move not/valid")

          wait_for_requests

          expect(page).to have_content 'Commands applied'
          expect(issue.reload).to be_open
        end
      end

      context 'when the user issues multiple commands' do
        let(:target_project) { create(:project, :public) }
        let(:milestone) { create(:milestone, title: '1.0', project: project) }
        let(:target_milestone) { create(:milestone, title: '1.0', project: target_project) }
        let(:bug)      { create(:label, project: project, title: 'bug') }
        let(:wontfix)  { create(:label, project: project, title: 'wontfix') }
        let(:bug_target)      { create(:label, project: target_project, title: 'bug') }
        let(:wontfix_target)  { create(:label, project: target_project, title: 'wontfix') }

        before do
          target_project.add_maintainer(user)
          gitlab_sign_out
          sign_in(user)
          visit project_issue_path(project, issue)
        end

        it 'applies the commands to both issues and moves the issue' do
          add_note("/label ~#{bug.title} ~#{wontfix.title}\n\n/milestone %\"#{milestone.title}\"\n\n/move #{target_project.full_path}")

          expect(page).to have_content 'Commands applied'
          expect(issue.reload).to be_closed

          visit project_issue_path(target_project, issue)

          expect(page).to have_content 'bug'
          expect(page).to have_content 'wontfix'
          expect(page).to have_content '1.0'

          visit project_issue_path(project, issue)
          expect(page).to have_content 'Closed'
          expect(page).to have_content 'bug'
          expect(page).to have_content 'wontfix'
          expect(page).to have_content '1.0'
        end

        it 'moves the issue and applies the commands to both issues' do
          add_note("/move #{target_project.full_path}\n\n/label ~#{bug.title} ~#{wontfix.title}\n\n/milestone %\"#{milestone.title}\"")

          expect(page).to have_content 'Commands applied'
          expect(issue.reload).to be_closed

          visit project_issue_path(target_project, issue)

          expect(page).to have_content 'bug'
          expect(page).to have_content 'wontfix'
          expect(page).to have_content '1.0'

          visit project_issue_path(project, issue)
          expect(page).to have_content 'Closed'
          expect(page).to have_content 'bug'
          expect(page).to have_content 'wontfix'
          expect(page).to have_content '1.0'
        end
      end
    end

    describe 'create a merge request starting from an issue' do
      let(:project) { create(:project, :public, :repository) }
      let(:issue) { create(:issue, project: project) }

      def expect_mr_quickaction(success)
        expect(page).to have_content 'Commands applied'

        if success
          expect(page).to have_content 'created merge request'
        else
          expect(page).not_to have_content 'created merge request'
        end
      end

      it "doesn't create a merge request when the branch name is invalid" do
        add_note("/create_merge_request invalid branch name")

        wait_for_requests

        expect_mr_quickaction(false)
      end

      it "doesn't create a merge request when a branch with that name already exists" do
        add_note("/create_merge_request feature")

        wait_for_requests

        expect_mr_quickaction(false)
      end

      it 'creates a new merge request using issue iid and title as branch name when the branch name is empty' do
        add_note("/create_merge_request")

        wait_for_requests

        expect_mr_quickaction(true)

        created_mr = project.merge_requests.last
        expect(created_mr.source_branch).to eq(issue.to_branch_name)

        visit project_merge_request_path(project, created_mr)
        expect(page).to have_content %{WIP: Resolve "#{issue.title}"}
      end

      it 'creates a merge request using the given branch name' do
        branch_name = '1-feature'
        add_note("/create_merge_request #{branch_name}")

        expect_mr_quickaction(true)

        created_mr = project.merge_requests.last
        expect(created_mr.source_branch).to eq(branch_name)

        visit project_merge_request_path(project, created_mr)
        expect(page).to have_content %{WIP: Resolve "#{issue.title}"}
      end
    end
  end
end
