require 'rails_helper'

feature 'Merge request approvals', js: true, feature: true do
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
end
