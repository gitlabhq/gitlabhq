require 'spec_helper'

feature 'Dashboard > milestone filter', :js do
  include FilterItemSelectHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'test', namespace: user.namespace) }
  let(:milestone) { create(:milestone, title: 'v1.0', project: project) }
  let(:milestone2) { create(:milestone, title: 'v2.0', project: project) }
  let!(:issue) { create :issue, author: user, project: project, milestone: milestone }
  let!(:issue2) { create :issue, author: user, project: project, milestone: milestone2 }

  before do
    sign_in(user)
    visit issues_dashboard_path(author_id: user.id)
  end

  context 'default state' do
    it 'shows issues with Any Milestone' do
      page.all('.issue-info').each do |issue_info|
        expect(issue_info.text).to match(/v\d.0/)
      end
    end
  end

  context 'filtering by milestone' do
    milestone_select_selector = '.js-milestone-select'

    before do
      filter_item_select('v1.0', milestone_select_selector)
      find(milestone_select_selector).click
      wait_for_requests
    end

    it 'shows issues with Milestone v1.0' do
      expect(find('.issues-list')).to have_selector('.issue', count: 1)
      expect(find('.dropdown-content')).to have_selector('a.is-active', count: 1)
    end

    it 'should not change active Milestone unless clicked' do
      expect(find('.dropdown-content')).to have_selector('a.is-active', count: 1)

      # open & close dropdown
      find('.dropdown-menu-close').click

      expect(find('.milestone-filter')).not_to have_selector('.dropdown.open')

      find(milestone_select_selector).click

      expect(find('.dropdown-content')).to have_selector('a.is-active', count: 1)
      expect(find('.dropdown-content a.is-active')).to have_content('v1.0')
    end
  end
end
