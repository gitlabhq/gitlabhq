require 'rails_helper'

feature 'Merge request approvals', js: true, feature: true do
  include WaitForAjax

  let(:user) { create(:user) }
  let(:project) { create(:project, approvals_before_merge: 1) }

  context 'when editing an MR with a different author' do
    let(:author) { create(:user) }
    let(:merge_request) { create(:merge_request, author: author, source_project: project) }

    before do
      project.team << [user, :developer]
      project.team << [author, :developer]

      login_as(user)
      visit edit_namespace_project_merge_request_path(project.namespace, project, merge_request)

      find('#s2id_merge_request_approver_ids .select2-input').click
    end

    it 'does not allow setting the author as an approver' do
      expect(find('.select2-results')).not_to have_content(author.name)
    end

    it 'allows setting the current user as an approver' do
      expect(find('.select2-results')).to have_content(user.name)
    end
  end

  context 'when creating an MR' do
    let(:other_user) { create(:user) }

    before do
      project.team << [user, :developer]
      project.team << [other_user, :developer]

      login_as(user)
      visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { target_branch: 'master', source_branch: 'feature' })

      find('#s2id_merge_request_approver_ids .select2-input').click
    end

    it 'allows setting other users as approvers' do
      expect(find('.select2-results')).to have_content(other_user.name)
    end

    it 'does not allow setting the current user as an approver' do
      expect(find('.select2-results')).not_to have_content(user.name)
    end
  end

  context "Group approvers" do
    context 'when creating an MR' do
      let(:other_user) { create(:user) }

      before do
        project.team << [user, :developer]
        project.team << [other_user, :developer]

        login_as(user)
      end

      it 'allows setting groups as approvers' do
        group = create :group
        group.add_developer(other_user)

        visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { target_branch: 'master', source_branch: 'feature' })
        find('#s2id_merge_request_approver_group_ids .select2-input').click

        wait_for_ajax

        expect(find('.select2-results')).to have_content(group.name)

        find('.select2-results').click
        click_on("Submit merge request")

        find('.approvals-components')
        expect(page).to have_content("Requires 1 more approval (from #{other_user.name})")
      end

      it 'allows delete approvers group when it is set in project' do
        approver = create :user
        group = create :group
        group.add_developer(other_user)
        create :approver_group, group: group, target: project
        create :approver, user: approver, target: project

        visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { target_branch: 'master', source_branch: 'feature' })

        within('.approver-list li.approver-group') do
          click_on "Remove"
        end

        expect(page).to have_css('.approver-list li', count: 1)

        click_on("Submit merge request")

        wait_for_ajax
        find('.approvals-components')
        expect(page).not_to have_content("Requires 1 more approval (from #{other_user.name})")
      end
    end

    context 'when editing an MR with a different author' do
      let(:other_user) { create(:user) }
      let(:merge_request) { create(:merge_request, source_project: project) }

      before do
        project.team << [user, :developer]

        login_as(user)
      end

      it 'allows setting groups as approvers' do
        group = create :group
        group.add_developer(other_user)
        group.add_developer(user)

        visit edit_namespace_project_merge_request_path(project.namespace, project, merge_request)
        find('#s2id_merge_request_approver_group_ids .select2-input').click

        wait_for_ajax

        expect(find('.select2-results')).to have_content(group.name)

        find('.select2-results').click
        click_on("Save changes")

        wait_for_ajax
        find('.approvals-components')
        expect(page).to have_content("Requires 1 more approval")
      end

      it 'allows delete approvers group when it`s set in project' do
        approver = create :user
        group = create :group
        group.add_developer(other_user)
        create :approver_group, group: group, target: project
        create :approver, user: approver, target: project

        visit edit_namespace_project_merge_request_path(project.namespace, project, merge_request)

        within('.approver-list li.approver-group') do
          click_on "Remove"
        end

        expect(page).to have_css('.approver-list li', count: 1)

        click_on("Save changes")

        find('.approvals-components')
        expect(page).to have_content("Requires 1 more approval (from #{approver.name})")
      end

      it 'allows changing approvals number' do
        create_list :approver, 3, target: project

        visit namespace_project_merge_request_path(project.namespace, project, merge_request)

        # project setting in the beginning on the show MR page
        find('.approvals-components')
        expect(page).to have_content("Requires 1 more approval")

        find('.merge-request').click_on 'Edit'

        # project setting in the beginning on the edit MR page
        expect(find('#merge_request_approvals_before_merge').value).to eq('1')
        expect(find('#merge_request_approvals_before_merge ~ .help-block')).to have_content('1 user')

        fill_in 'merge_request_approvals_before_merge', with: '3'

        click_on('Save changes')

        # new MR setting on the show MR page
        find('.approvals-components')
        expect(page).to have_content("Requires 3 more approvals")

        find('.merge-request').click_on 'Edit'

        # new MR setting on the edit MR page
        expect(find('#merge_request_approvals_before_merge').value).to eq('3')
        expect(find('#merge_request_approvals_before_merge ~ .help-block')).to have_content('1 user')
      end
    end
  end

  context 'Approving by approvers from groups' do
    let(:other_user) { create(:user) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let(:group) { create :group }

    before do
      project.team << [user, :developer]

      group.add_developer(other_user)
      group.add_developer(user)

      login_as(user)
    end

    context 'when group is assigned to a project', js: true do
      before do
        create :approver_group, group: group, target: project
        visit namespace_project_merge_request_path(project.namespace, project, merge_request)
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
        visit namespace_project_merge_request_path(project.namespace, project, merge_request)
      end

      it 'I am able to approve' do
        approve_merge_request
        wait_for_ajax
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
        create(:ci_empty_pipeline, project: project, sha: merge_request.diff_head_sha, ref: merge_request.source_branch)
        visit namespace_project_merge_request_path(project.namespace, project, merge_request)
      end

      it 'I am unable to set Merge When Pipeline Succeeds' do
        # before approval status is loaded
        expect(page).to have_button('Merge When Pipeline Succeeds', disabled: true)

        wait_for_ajax

        # after approval status is loaded
        expect(page).to have_button('Merge When Pipeline Succeeds', disabled: true)
      end
    end

    context 'when rebase is needed but no approval given', js: true do
      let(:project) do
        create(:project,
          approvals_before_merge: 1,
          merge_requests_rebase_enabled: true,
          merge_requests_ff_only_enabled: true )
      end

      let(:merge_request) { create(:merge_request, source_project: project) }

      before do
        create :approver_group, group: group, target: merge_request
        visit namespace_project_merge_request_path(project.namespace, project, merge_request)
      end

      it 'I am unable to rebase the merge request' do
        # before approval status is loaded
        expect(page).to have_button("Rebase onto #{merge_request.target_branch}", disabled: true)

        wait_for_ajax

        # after approval status is loaded
        expect(page).to have_button("Rebase onto #{merge_request.target_branch}", disabled: true)
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
      project.team << [user, :developer]
      login_as(user)

      visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { target_branch: 'master', source_branch: 'feature' })

      click_button 'Submit merge request'
    end

    it 'does not show checking ability text' do
      expect(find('.mr-widget-body')).not_to have_text('Checking ability to merge automatically')
      expect(find('.mr-widget-body')).to have_selector('.accept-action')
    end
  end
end

def approve_merge_request
  page.within '.mr-state-widget' do
    click_button 'Approve Merge Request'
  end
  wait_for_ajax
end

def unapprove_merge_request
  page.within '.mr-state-widget' do
    find('.unapprove-btn-wrap').click
  end
  wait_for_ajax
end
