require 'rails_helper'

describe 'New/edit issue', feature: true, js: true do
  let!(:project)   { create(:project) }
  let!(:user)      { create(:user)}
  let!(:milestone) { create(:milestone, project: project) }
  let!(:label)     { create(:label, project: project) }
  let!(:label2)    { create(:label, project: project) }
  let!(:issue)     { create(:issue, project: project, assignee: user, milestone: milestone) }

  before do
    project.team << [user, :master]
    login_as(user)
  end

  context 'new issue' do
    before do
      visit new_namespace_project_issue_path(project.namespace, project)
    end

    it 'should allow user to create new issue' do
      fill_in 'issue_title', with: 'title'
      fill_in 'issue_description', with: 'title'

      click_button 'Assignee'
      click_link user.name

      page.find '.js-assignee-search' do
        expect(page).to have_content user.name
      end

      click_button 'Milestone'
      click_link milestone.title

      page.find '.js-milestone-select' do
        expect(page).to have_content milestone.title
      end

      click_button 'Labels'
      click_link label.title
      click_link label2.title

      page.find '.js-label-select' do
        expect(page).to have_content label2.title
      end

      click_button 'Submit issue'

      page.find '.issuable-sidebar' do
        expect(page).to have_content user.name
        expect(page).to have_content milestone.title
        expect(page).to have_content label.title
        expect(page).to have_content label2.title
      end
    end
  end

  context 'edit issue' do
    before do
      visit edit_namespace_project_issue_path(project.namespace, project, issue)
    end

    it 'should allow user to update issue' do
      expect(page).to have_content user.name
      expect(page).to have_content milestone.title

      click_button 'Labels'
      click_link label.title
      click_link label2.title

      page.find '.js-label-select' do
        expect(page).to have_content label2.title
      end

      click_button 'Save changes'

      page.find '.issuable-sidebar' do
        expect(page).to have_content user.name
        expect(page).to have_content milestone.title
        expect(page).to have_content label.title
        expect(page).to have_content label2.title
      end
    end
  end
end
