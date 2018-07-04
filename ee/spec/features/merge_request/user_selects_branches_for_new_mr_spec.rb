require 'rails_helper'

describe 'Merge request > User selects branches for new MR', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }

  def select_source_branch(branch_name)
    find('.js-source-branch', match: :first).click
    find('.js-source-branch-dropdown .dropdown-input-field').native.send_keys branch_name
    find('.js-source-branch-dropdown .dropdown-content a', text: branch_name, match: :first).click
  end

  before do
    project.add_master(user)
    sign_in(user)
  end

  context 'when approvals are zero for the target project' do
    before do
      project.update_attributes(approvals_before_merge: 0)

      visit project_new_merge_request_path(project, merge_request: { target_branch: 'master', source_branch: 'feature_conflict' })
    end

    it 'shows approval settings' do
      expect(page).to have_content('Approvers')
    end
  end
end
