require 'rails_helper'

feature 'Merge request > User approves', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository, approvals_before_merge: 1) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  context 'Approving by approvers from groups' do
    let(:other_user) { create(:user) }
    let(:group) { create :group }

    before do
      project.add_developer(user)
      group.add_developer(other_user)
      group.add_developer(user)

      sign_in(user)
    end

    context 'when group is assigned to a project' do
      before do
        create :approver_group, group: group, target: project
        visit project_merge_request_path(project, merge_request)
      end

      it 'I am able to approve' do
        approve_merge_request

        expect(page).to have_content('Approved by')
        expect(page).to have_css('.approver-avatar')
      end

      it 'I am able to unapprove' do
        approve_merge_request
        unapprove_merge_request

        expect(page).to have_no_css('.approver-avatar')
      end
    end

    context 'when group is assigned to a merge request' do
      before do
        create :approver_group, group: group, target: merge_request
        visit project_merge_request_path(project, merge_request)
      end

      it 'I am able to approve' do
        approve_merge_request

        expect(page).to have_content('Approved by')
        expect(page).to have_css('.approver-avatar')
      end

      it 'I am able to unapprove' do
        approve_merge_request
        unapprove_merge_request

        expect(page).to have_no_css('.approver-avatar')
      end
    end

    context 'when CI is running but no approval given' do
      before do
        create :approver_group, group: group, target: merge_request
        pipeline = create(:ci_empty_pipeline, project: project, sha: merge_request.diff_head_sha, ref: merge_request.source_branch)
        merge_request.update(head_pipeline: pipeline)
        visit project_merge_request_path(project, merge_request)
      end

      it 'I am unable to set Merge when pipeline succeeds' do
        # before approval status is loaded
        expect(page).to have_button('Merge when pipeline succeeds', disabled: true)

        wait_for_requests

        # after approval status is loaded
        expect(page).to have_button('Merge when pipeline succeeds', disabled: true)
      end
    end
  end

  context 'when merge when discussions resolved is active' do
    let(:project) do
      create(:project, :repository,
        approvals_before_merge: 1,
        only_allow_merge_if_all_discussions_are_resolved: true)
    end

    before do
      project.add_developer(user)
      sign_in(user)

      visit project_merge_request_path(project, merge_request)
    end

    it 'does not show checking ability text' do
      expect(find('.mr-widget-approvals-container')).not_to have_text('Checking ability to merge automatically')
      expect(find('.mr-widget-approvals-container')).to have_selector('.approvals-body')
    end
  end
end

def approve_merge_request
  page.within '.mr-state-widget' do
    find('.approve-btn').click
  end
  wait_for_requests
end

def unapprove_merge_request
  page.within '.mr-state-widget' do
    find('.unapprove-btn-wrap').click
  end
  wait_for_requests
end
