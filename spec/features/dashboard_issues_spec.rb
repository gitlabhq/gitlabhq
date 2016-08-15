require 'spec_helper'

describe "Dashboard Issues filtering", feature: true, js: true do
  let(:user)      { create(:user) }
  let(:project)   { create(:project) }
  let(:milestone) { create(:milestone, project: project) }

  context 'filtering by milestone' do
    before do
      project.team << [user, :master]
      login_as(user)

      create(:issue, project: project, author: user, assignee: user)
      create(:issue, project: project, author: user, assignee: user, milestone: milestone)

      visit_issues
    end

    it 'shows all issues with no milestone' do
      show_milestone_dropdown

      click_link 'No Milestone'

      expect(page).to have_selector('.issue', count: 1)
    end

    it 'shows all issues with any milestone' do
      show_milestone_dropdown

      click_link 'Any Milestone'

      expect(page).to have_selector('.issue', count: 2)
    end

    it 'shows all issues with the selected milestone' do
      show_milestone_dropdown

      page.within '.dropdown-content' do
        click_link milestone.title
      end

      expect(page).to have_selector('.issue', count: 1)
    end
  end

  def show_milestone_dropdown
    click_button 'Milestone'
    expect(page).to have_selector('.dropdown-content', visible: true)
  end

  def visit_issues
    visit issues_dashboard_path
  end
end
