require 'spec_helper'

feature 'Dashboard > milestone filter', :js do
  include FilterItemSelectHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'test', namespace: user.namespace) }
  let(:milestone) { create(:milestone, title: 'v1.0', project: project) }
  let(:milestone2) { create(:milestone, title: 'v2.0', project: project) }
  let!(:issue) { create :issue, author: user, project: project, milestone: milestone }
  let!(:issue2) { create :issue, author: user, project: project, milestone: milestone2 }

  dropdown_toggle_button = '.js-milestone-select'

  before do
    sign_in(user)
  end

  context 'default state' do
    it 'shows issues with Any Milestone' do
      visit issues_dashboard_path(author_id: user.id)

      page.all('.issue-info').each do |issue_info|
        expect(issue_info.text).to match(/v\d.0/)
      end
    end
  end

  context 'filtering by milestone' do
    before do
      visit issues_dashboard_path(author_id: user.id)
      filter_item_select('v1.0', dropdown_toggle_button)
      find(dropdown_toggle_button).click
      wait_for_requests
    end

    it 'shows issues with Milestone v1.0' do
      expect(find('.issues-list')).to have_selector('.issue', count: 1)
      expect(find('.milestone-filter .dropdown-content')).to have_selector('a.is-active', count: 1)
    end

    it 'should not change active Milestone unless clicked' do
      page.within '.milestone-filter' do
        expect(find('.dropdown-content')).to have_selector('a.is-active', count: 1)

        find('.dropdown-menu-close').click

        expect(page).not_to have_selector('.dropdown.open')

        find(dropdown_toggle_button).click

        expect(find('.dropdown-content')).to have_selector('a.is-active', count: 1)
        expect(find('.dropdown-content a.is-active')).to have_content('v1.0')
      end
    end
  end

  context 'with milestone filter in URL' do
    before do
      visit issues_dashboard_path(author_id: user.id, milestone_title: milestone.title)
      find(dropdown_toggle_button).click
      wait_for_requests
    end

    it 'has milestone selected' do
      expect(find('.milestone-filter .dropdown-content')).to have_css('.is-active', text: milestone.title)
    end

    it 'removes milestone filter from URL after clicking "Any Milestone"' do
      expect(current_url).to include("milestone_title=#{milestone.title}")

      find('.milestone-filter .dropdown-content li', text: 'Any Milestone').click

      expect(current_url).not_to include('milestone_title')
    end
  end
end
