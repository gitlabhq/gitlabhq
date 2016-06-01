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

    it 'should allow user to update title' do
      find('.js-issuable-title').click
      expect(page).to have_selector('.js-issuable-edit-title', visible: true)
      fill_in 'issue_title', with: 'test'
      click_button 'Save'

      page.within '.issuable-details' do
        expect(page).to have_content 'test'
      end
    end

    it 'should hide title field' do
      find('.js-issuable-title').click
      expect(page).to have_selector('.js-issuable-edit-title', visible: true)
      click_button 'Cancel'
      expect(page).to have_selector('.js-issuable-edit-title', visible: false)
    end

    it 'should allow user to update description' do
      find('.js-issuable-description').click
      expect(page).to have_selector('.js-issuable-description-field', visible: true)
      fill_in 'issue_description', with: 'test'
      click_button 'Save'

      page.within '.issuable-details' do
        expect(page).to have_content 'test'
      end
    end

    it 'should hide description field' do
      find('.js-issuable-description').click
      expect(page).to have_selector('.js-issuable-description-field', visible: true)
      click_button 'Cancel'
      expect(page).to have_selector('.js-issuable-description-field', visible: false)
    end
  end

  context 'user is not allowed to edit issue' do
    before do
      login_as(user)
      visit namespace_project_issue_path(project.namespace, project, issue)
    end

    it 'should not allow editing of title' do
      expect(page).not_to have_selector('.js-issuable-title', visible: false)
    end

    it 'should not allow editing of description' do
      expect(page).not_to have_selector('.js-issuable-description', visible: false)
    end
  end
end
