require 'rails_helper'

feature 'Merge request approvals', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, approvals_before_merge: 1) }

  context 'when editing an MR with a different author' do
    let(:author) { create(:user) }
    let(:merge_request) { create(:merge_request, author: author, source_project: project) }

    before do
      project.add_developer(user)
      project.add_developer(author)

      sign_in(user)
      visit edit_project_merge_request_path(project, merge_request)

      find('#s2id_merge_request_approver_ids .select2-input').click
    end

    it 'does not allow setting the author as an approver' do
      expect(find('.select2-results')).not_to have_content(author.name)
    end

    it 'allows setting the current user as an approver' do
      expect(find('.select2-results')).to have_content(user.name)
    end
  end

  context 'when creating an MR from a fork' do
    let(:other_user) { create(:user) }
    let(:non_member) { create(:user) }
    let(:forked_project) { create(:project, :public, creator: user) }

    before do
      create(:forked_project_link, forked_to_project: forked_project, forked_from_project: project)

      forked_project.add_developer(user)
      project.add_developer(user)
      project.add_developer(other_user)

      sign_in(user)
      visit project_new_merge_request_path(forked_project, merge_request: { target_branch: 'master', source_branch: 'feature' })

      find('#s2id_merge_request_approver_ids .select2-input').click
    end

    it 'allows setting other users as approvers' do
      expect(find('.select2-results')).to have_content(other_user.name)
    end

    it 'does not allow setting the current user as an approver' do
      expect(find('.select2-results')).not_to have_content(user.name)
    end

    it 'filters non members from approvers list' do
      expect(find('.select2-results')).not_to have_content(non_member.name)
    end
  end

  context "Group approvers" do
    context 'when creating an MR' do
      let(:other_user) { create(:user) }

      before do
        project.add_developer(user)
        project.add_developer(other_user)

        sign_in(user)
      end

      it 'allows setting groups as approvers' do
        group = create :group
        group.add_developer(other_user)

        visit project_new_merge_request_path(project, merge_request: { target_branch: 'master', source_branch: 'feature' })
        find('#s2id_merge_request_approver_group_ids .select2-input').click

        wait_for_requests

        expect(find('.select2-results')).to have_content(group.name)

        find('.select2-results').click
        click_on("Submit merge request")

        find('.approvals-components')
        expect(page).to have_content("Requires 1 more approval")
        expect(page).to have_selector(".approvals-required-text a[title='#{other_user.name}']")
      end

      it 'allows delete approvers group when it is set in project' do
        approver = create :user
        group = create :group
        group.add_developer(other_user)
        create :approver_group, group: group, target: project
        create :approver, user: approver, target: project

        visit project_new_merge_request_path(project, merge_request: { target_branch: 'master', source_branch: 'feature' })

        within('.approver-list li.approver-group') do
          click_on "Remove"
        end

        expect(page).to have_css('.approver-list li', count: 1)

        click_on("Submit merge request")

        wait_for_requests

        expect(page).not_to have_selector(".approvals-required-text a[title='#{other_user.name}']")
        expect(page).to have_selector(".approvals-required-text a[title='#{approver.name}']")
        expect(page).to have_content("Requires 1 more approval")
      end
    end

    context 'when editing an MR with a different author' do
      let(:other_user) { create(:user) }
      let(:merge_request) { create(:merge_request, source_project: project) }

      before do
        project.add_developer(user)

        sign_in(user)
      end

      it 'allows setting groups as approvers' do
        group = create :group
        group.add_developer(other_user)
        group.add_developer(user)

        visit edit_project_merge_request_path(project, merge_request)
        find('#s2id_merge_request_approver_group_ids .select2-input').click

        wait_for_requests

        expect(find('.select2-results')).to have_content(group.name)

        find('.select2-results').click
        click_on("Save changes")

        wait_for_requests
        find('.approvals-components')
        expect(page).to have_content("Requires 1 more approval")
      end

      it 'allows delete approvers group when it`s set in project' do
        approver = create :user
        group = create :group
        group.add_developer(other_user)
        create :approver_group, group: group, target: project
        create :approver, user: approver, target: project

        visit edit_project_merge_request_path(project, merge_request)

        within('.approver-list li.approver-group') do
          click_on "Remove"
        end

        expect(page).to have_css('.approver-list li', count: 1)

        click_on("Save changes")

        find('.approvals-components')
        expect(page).to have_content("Requires 1 more approval")
        expect(page).to have_selector(".approvals-required-text a[title='#{approver.name}']")
      end

      it 'allows changing approvals number' do
        create_list :approver, 3, target: project

        visit project_merge_request_path(project, merge_request)

        # project setting in the beginning on the show MR page
        find('.approvals-components')
        expect(page).to have_content("Requires 1 more approval")

        find('.merge-request').click_on 'Edit'

        # project setting in the beginning on the edit MR page
        expect(find('#merge_request_approvals_before_merge').value).to eq('1')

        fill_in 'merge_request_approvals_before_merge', with: '3'

        click_on('Save changes')

        # new MR setting on the show MR page
        find('.approvals-components')
        expect(page).to have_content("Requires 3 more approvals")

        find('.merge-request').click_on 'Edit'

        # new MR setting on the edit MR page
        expect(find('#merge_request_approvals_before_merge').value).to eq('3')
      end
    end
  end

  context 'Approving by approvers from groups' do
    let(:other_user) { create(:user) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let(:group) { create :group }

    before do
      project.add_developer(user)
      group.add_developer(other_user)
      group.add_developer(user)

      sign_in(user)
    end

    context 'when group is assigned to a project', js: true do
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

    context 'when group is assigned to a merge request', js: true do
      before do
        create :approver_group, group: group, target: merge_request
        visit project_merge_request_path(project, merge_request)
      end

      it 'I am able to approve' do
        approve_merge_request
        wait_for_requests
        expect(page).to have_content('Approved by')
        expect(page).to have_css('.approver-avatar')
      end

      it 'I am able to unapprove' do
        approve_merge_request
        unapprove_merge_request
        expect(page).to have_no_css('.approver-avatar')
      end
    end

    context 'when CI is running but no approval given', js: true do
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

  context 'when merge when discussions resolved is active', :js do
    let(:project) do
      create(:project,
        approvals_before_merge: 1,
        only_allow_merge_if_all_discussions_are_resolved: true)
    end

    before do
      project.add_developer(user)
      sign_in(user)

      visit project_new_merge_request_path(project, merge_request: { target_branch: 'master', source_branch: 'feature' })

      click_button 'Submit merge request'
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
