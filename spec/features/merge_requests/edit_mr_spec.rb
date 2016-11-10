require 'spec_helper'

feature 'Edit Merge Request', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:merge_request) { create(:merge_request, :simple, source_project: project) }

  before do
    project.team << [user, :master]

    login_as user

    visit edit_namespace_project_merge_request_path(project.namespace, project, merge_request)
  end

  context 'editing a MR' do
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

    it 'allows to unselect "Remove source branch"' do
      merge_request.update(merge_params: { 'force_remove_source_branch' => '1' })
      expect(merge_request.merge_params['force_remove_source_branch']).to be_truthy

      visit edit_namespace_project_merge_request_path(project.namespace, project, merge_request)
      uncheck 'Remove source branch when merge request is accepted'

      click_button 'Save changes'

      expect(page).to have_content 'Remove source branch'
    end
  end
end
