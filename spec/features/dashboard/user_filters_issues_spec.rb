require 'spec_helper'

describe 'Dashboard > user filter', feature: true, js: true do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:project) { create(:project, name: 'Victorialand', namespace: user.namespace) }

  let!(:authored_issue) { create :issue, author: user, assignees: [], project: project }
  let!(:assigned_issue) { create :issue, author: user2, assignees: [user], project: project }

  before do
    project.team << [user, :master]

    login_as(user)
  end

  it 'should select Any Assignee by default' do
    visit issues_dashboard_path

    find('.js-assignee-search').click

    expect(find('[data-user-id="null"]')).to have_selector('.is-active')
  end

  context 'filtering by author' do
    it 'shows issues authored by user' do
      visit issues_dashboard_path(author_id: user.id)

      expect(find('.js-author-search')).to have_content(user.name)
      expect(find('.issue-info')).to have_content(user.name)

      find('.js-author-search').click

      expect(find("[data-user-id=\"#{user.id}\"]")).to have_selector('.is-active')
    end
  end

  context 'filtering by assignee' do
    it 'shows Unassigned issues' do
      visit issues_dashboard_path(assignee_id: 0)

      expect(find('.issue .controls')).not_to have_selector('.author_link')
    end

    it 'shows issues assigned to user' do
      visit issues_dashboard_path(assignee_id: user.id)

      expect(find('.issue .controls')).to have_selector('.author_link')

      find('.js-assignee-search').click

      expect(find("[data-user-id=\"#{user.id}\"]")).to have_selector('.is-active')
    end

    it 'does not change active item until new item is selected' do
      visit issues_dashboard_path(assignee_id: 0)
      active = '.is-active'
      assignee_search = find('.js-assignee-search')
      assignee_search.click

      any_assignee = find('[data-user-id="null"]')
      unassigned = find('[data-user-id="0"]')

      expect(unassigned).to have_selector(active)
      expect(any_assignee).not_to have_selector(active)

      # close then open dropdown
      assignee_search.click
      assignee_search.click

      # active should be the same
      expect(unassigned).to have_selector(active)

      # should change active when selecting new item
      any_assignee.click

      assignee_search.click

      expect(any_assignee).to have_selector(active)
      expect(unassigned).not_to have_selector(active)
    end
  end
end
