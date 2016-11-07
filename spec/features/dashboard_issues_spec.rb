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

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_selector('.issue', count: 1)
    end

    it 'shows all issues with any milestone' do
      show_milestone_dropdown

      click_link 'Any Milestone'

      expect(page).to have_issuable_counts(open: 2, closed: 0, all: 2)
      expect(page).to have_selector('.issue', count: 2)
    end

    it 'shows all issues with the selected milestone' do
      show_milestone_dropdown

      page.within '.dropdown-content' do
        click_link milestone.title
      end

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_selector('.issue', count: 1)
    end

    it 'updates atom feed link' do
      visit_issues(milestone_title: '', assignee_id: user.id)

      link = find('.nav-controls a', text: 'Subscribe')
      params = CGI::parse(URI.parse(link[:href]).query)
      auto_discovery_link = find('link[type="application/atom+xml"]', visible: false)
      auto_discovery_params = CGI::parse(URI.parse(auto_discovery_link[:href]).query)

      expect(params).to include('private_token' => [user.private_token])
      expect(params).to include('milestone_title' => [''])
      expect(params).to include('assignee_id' => [user.id.to_s])
      expect(auto_discovery_params).to include('private_token' => [user.private_token])
      expect(auto_discovery_params).to include('milestone_title' => [''])
      expect(auto_discovery_params).to include('assignee_id' => [user.id.to_s])
    end
  end

  def show_milestone_dropdown
    click_button 'Milestone'
    expect(page).to have_selector('.dropdown-content', visible: true)
  end

  def visit_issues(*args)
    visit issues_dashboard_path(*args)
  end
end
