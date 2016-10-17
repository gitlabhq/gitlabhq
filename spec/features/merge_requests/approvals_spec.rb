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
      visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { source_branch: 'feature' })

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

        visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { source_branch: 'feature' })
        find('#s2id_merge_request_approver_group_ids .select2-input').click

        wait_for_ajax

        expect(find('.select2-results')).to have_content(group.name)

        find('.select2-results').click
        click_on("Submit merge request")
        expect(page).to have_content("Requires one more approval (from #{other_user.name})")
      end

      it 'allows delete approvers group when it is set in project' do
        approver = create :user
        group = create :group
        group.add_developer(other_user)
        create :approver_group, group: group, target: project
        create :approver, user: approver, target: project

        visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { source_branch: 'feature' })

        within('.approver-list li.approver-group') do
          click_on "Remove"
        end

        expect(page).to have_css('.approver-list li', count: 1)

        click_on("Submit merge request")
        expect(page).not_to have_content("Requires one more approval (from #{other_user.name})")
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

        expect(page).to have_content("Requires one more approval")
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
        expect(page).to have_content("Requires one more approval (from #{approver.name})")
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

    context 'when group is assigned to a project' do
      it 'I am able to approve' do
        create :approver_group, group: group, target: project

        visit namespace_project_merge_request_path(project.namespace, project, merge_request)

        page.within '.mr-state-widget' do
          click_button 'Approve Merge Request'
        end

        expect(page).to have_content("Approved by")
      end
    end

    context 'when group is assigned to a merge request' do
      it 'I am able to approve' do
        create :approver_group, group: group, target: merge_request

        visit namespace_project_merge_request_path(project.namespace, project, merge_request)

        page.within '.mr-state-widget' do
          click_button 'Approve Merge Request'
        end

        expect(page).to have_content("Approved by")
      end
    end
  end
end
