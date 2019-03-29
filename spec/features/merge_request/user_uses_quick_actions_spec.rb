require 'rails_helper'

describe 'Merge request > User uses quick actions', :js do
  include Spec::Support::Helpers::Features::NotesHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:guest) { create(:user) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let!(:milestone) { create(:milestone, project: project, title: 'ASAP') }

  context "issuable common quick actions" do
    let!(:new_url_opts) { { merge_request: { source_branch: 'feature', target_branch: 'master' } } }
    let(:maintainer) { create(:user) }
    let(:project) { create(:project, :public, :repository) }
    let!(:label_bug) { create(:label, project: project, title: 'bug') }
    let!(:label_feature) { create(:label, project: project, title: 'feature') }
    let!(:milestone) { create(:milestone, project: project, title: 'ASAP') }
    let(:issuable) { create(:merge_request, source_project: project) }
    let(:source_issuable) { create(:issue, project: project, milestone: milestone, labels: [label_bug, label_feature])}

    it_behaves_like 'assign quick action', :merge_request
    it_behaves_like 'unassign quick action', :merge_request
    it_behaves_like 'close quick action', :merge_request
    it_behaves_like 'reopen quick action', :merge_request
    it_behaves_like 'title quick action', :merge_request
    it_behaves_like 'todo quick action', :merge_request
    it_behaves_like 'done quick action', :merge_request
    it_behaves_like 'subscribe quick action', :merge_request
    it_behaves_like 'unsubscribe quick action', :merge_request
    it_behaves_like 'lock quick action', :merge_request
    it_behaves_like 'unlock quick action', :merge_request
    it_behaves_like 'milestone quick action', :merge_request
    it_behaves_like 'remove_milestone quick action', :merge_request
    it_behaves_like 'label quick action', :merge_request
    it_behaves_like 'unlabel quick action', :merge_request
    it_behaves_like 'relabel quick action', :merge_request
    it_behaves_like 'award quick action', :merge_request
    it_behaves_like 'estimate quick action', :merge_request
    it_behaves_like 'remove_estimate quick action', :merge_request
    it_behaves_like 'spend quick action', :merge_request
    it_behaves_like 'remove_time_spent quick action', :merge_request
    it_behaves_like 'shrug quick action', :merge_request
    it_behaves_like 'tableflip quick action', :merge_request
    it_behaves_like 'copy_metadata quick action', :merge_request
    it_behaves_like 'issuable time tracker', :merge_request
  end

  describe 'merge-request-only commands' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let!(:milestone) { create(:milestone, project: project, title: 'ASAP') }

    before do
      project.add_maintainer(user)
    end

    describe 'toggling the WIP prefix in the title from note' do
      context 'when the current user can toggle the WIP prefix' do
        before do
          sign_in(user)
          visit project_merge_request_path(project, merge_request)
          wait_for_requests
        end

        it 'adds the WIP: prefix to the title' do
          add_note("/wip")

          expect(page).not_to have_content '/wip'
          expect(page).to have_content 'Commands applied'

          expect(merge_request.reload.work_in_progress?).to eq true
        end

        it 'removes the WIP: prefix from the title' do
          merge_request.title = merge_request.wip_title
          merge_request.save
          add_note("/wip")

          expect(page).not_to have_content '/wip'
          expect(page).to have_content 'Commands applied'

          expect(merge_request.reload.work_in_progress?).to eq false
        end
      end

      context 'when the current user cannot toggle the WIP prefix' do
        before do
          project.add_guest(guest)
          sign_in(guest)
          visit project_merge_request_path(project, merge_request)
        end

        it 'does not change the WIP prefix' do
          add_note("/wip")

          expect(page).not_to have_content '/wip'
          expect(page).not_to have_content 'Commands applied'

          expect(merge_request.reload.work_in_progress?).to eq false
        end
      end
    end

    describe 'merging the MR from the note' do
      context 'when the current user can merge the MR' do
        before do
          sign_in(user)
          visit project_merge_request_path(project, merge_request)
        end

        it 'merges the MR' do
          add_note("/merge")

          expect(page).to have_content 'Commands applied'

          expect(merge_request.reload).to be_merged
        end
      end

      context 'when the head diff changes in the meanwhile' do
        before do
          merge_request.source_branch = 'another_branch'
          merge_request.save
          sign_in(user)
          visit project_merge_request_path(project, merge_request)
        end

        it 'does not merge the MR' do
          add_note("/merge")

          expect(page).not_to have_content 'Your commands have been executed!'

          expect(merge_request.reload).not_to be_merged
        end
      end

      context 'when the current user cannot merge the MR' do
        before do
          project.add_guest(guest)
          sign_in(guest)
          visit project_merge_request_path(project, merge_request)
        end

        it 'does not merge the MR' do
          add_note("/merge")

          expect(page).not_to have_content 'Your commands have been executed!'

          expect(merge_request.reload).not_to be_merged
        end
      end
    end

    describe 'adding a due date from note' do
      before do
        sign_in(user)
        visit project_merge_request_path(project, merge_request)
      end

      it_behaves_like 'due quick action not available'
    end

    describe 'removing a due date from note' do
      before do
        sign_in(user)
        visit project_merge_request_path(project, merge_request)
      end

      it_behaves_like 'remove_due_date action not available'
    end

    describe '/target_branch command in merge request' do
      let(:another_project) { create(:project, :public, :repository) }
      let(:new_url_opts) { { merge_request: { source_branch: 'feature' } } }

      before do
        another_project.add_maintainer(user)
        sign_in(user)
      end

      it 'changes target_branch in new merge_request' do
        visit project_new_merge_request_path(another_project, new_url_opts)

        fill_in "merge_request_title", with: 'My brand new feature'
        fill_in "merge_request_description", with: "le feature \n/target_branch fix\nFeature description:"
        click_button "Submit merge request"

        merge_request = another_project.merge_requests.first
        expect(merge_request.description).to eq "le feature \nFeature description:"
        expect(merge_request.target_branch).to eq 'fix'
      end

      it 'does not change target branch when merge request is edited' do
        new_merge_request = create(:merge_request, source_project: another_project)

        visit edit_project_merge_request_path(another_project, new_merge_request)
        fill_in "merge_request_description", with: "Want to update target branch\n/target_branch fix\n"
        click_button "Save changes"

        new_merge_request = another_project.merge_requests.first
        expect(new_merge_request.description).to include('/target_branch')
        expect(new_merge_request.target_branch).not_to eq('fix')
      end
    end

    describe '/target_branch command from note' do
      context 'when the current user can change target branch' do
        before do
          sign_in(user)
          visit project_merge_request_path(project, merge_request)
        end

        it 'changes target branch from a note' do
          add_note("message start \n/target_branch merge-test\n message end.")

          wait_for_requests
          expect(page).not_to have_content('/target_branch')
          expect(page).to have_content('message start')
          expect(page).to have_content('message end.')

          expect(merge_request.reload.target_branch).to eq 'merge-test'
        end

        it 'does not fail when target branch does not exists' do
          add_note('/target_branch totally_not_existing_branch')

          expect(page).not_to have_content('/target_branch')

          expect(merge_request.target_branch).to eq 'feature'
        end
      end

      context 'when current user can not change target branch' do
        before do
          project.add_guest(guest)
          sign_in(guest)
          visit project_merge_request_path(project, merge_request)
        end

        it 'does not change target branch' do
          add_note('/target_branch merge-test')

          expect(page).not_to have_content '/target_branch merge-test'

          expect(merge_request.target_branch).to eq 'feature'
        end
      end
    end
  end
end
