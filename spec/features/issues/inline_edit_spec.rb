require 'rails_helper'

describe 'Issue inline editing', feature: true, js: true do
  let(:project)   { create(:project, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
  let(:user)      { create(:user) }
  let(:issue)     { create(:issue, project: project, description: 'description') }

  context 'user is allowed to edit issue' do
    before do
      project.team << [user, :master]
      login_as(user)
      visit namespace_project_issue_path(project.namespace, project, issue)
    end

    it 'allows user to update title and description' do
      find('.js-inline-edit').click

      fill_in 'issue_title', with: 'title test'
      fill_in 'issue_description', with: 'description test'

      click_button 'Save changes'
      expect(page).to have_content 'title test'
      expect(page).to have_content 'description test'
    end
  end

  context 'user is not allowed to edit issue' do
    before do
      login_as(user)
      visit namespace_project_issue_path(project.namespace, project, issue)
    end

    it 'does not allow editing of title' do
      expect(page).not_to have_selector('.js-inline-edit', visible: false)
    end
  end
end
