require 'spec_helper'

feature 'Edit Merge Request', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:merge_request) { create(:merge_request, :with_diffs, source_project: project) }

  context 'editing a MR' do
    before do
      project.team << [user, :master]

      visit_edit_mr_page
    end

    it 'has class js-quick-submit in form' do
      expect(page).to have_selector('.js-quick-submit')
    end

    it 'warns about version conflict' do
      merge_request.update(title: "New title")

      fill_in 'merge_request_title', with: 'bug 345'
      fill_in 'merge_request_description', with: 'bug description'

      click_button 'Save changes'

      expect(page).to have_content 'Someone edited the merge request the same time you did'
    end
  end

  context 'saving the MR that needs approvals' do
    before do
      project.team << [user, :master]
      project.update_attributes(approvals_before_merge: 2)

      visit_edit_mr_page
    end

    it 'shows the saved MR' do
      click_button 'Save changes'

      expect(page).to have_link('Close merge request')
    end
  end

  def visit_edit_mr_page
    login_as user

    visit edit_namespace_project_merge_request_path(project.namespace, project, merge_request)
  end
end
