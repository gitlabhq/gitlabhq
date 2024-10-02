# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard shortcuts', :js, feature_category: :navigation do
  context 'logged in' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:issue) { create(:issue, title: 'Issue 1', project: project) }
    let_it_be(:todo) { create(:todo, target: issue, user: user) }

    before_all do
      group.add_developer(user)
    end

    before do
      sign_in(user)
      visit root_dashboard_path
    end

    it 'navigates to pages' do
      find('body').send_keys([:shift, 'I'])

      check_page_title('Issues')

      find('body').send_keys([:shift, 'M'])

      check_page_title('Merge requests')

      find('body').send_keys([:shift, 'R'])

      check_page_title('Merge requests')

      find('body').send_keys([:shift, 'T'])

      check_page_title('To-Do List')

      find('body').send_keys([:shift, 'G'])

      check_page_title('Groups')

      find('body').send_keys([:shift, 'P'])

      check_page_title('Projects')

      find('body').send_keys([:shift, 'A'])

      check_page_title('Activity')

      find('body').send_keys([:shift, 'L'])

      check_page_title('Milestones')
    end
  end

  context 'logged out' do
    before do
      visit explore_root_path
    end

    it 'navigates to pages' do
      find('body').send_keys([:shift, 'G'])

      expect(page).to have_content('No public or internal groups')

      find('body').send_keys([:shift, 'S'])

      expect(page).to have_content('There are no snippets found')

      find('body').send_keys([:shift, 'P'])

      find('.nothing-here-block')
      expect(page).to have_content('Explore public groups to find projects to contribute to')
    end
  end

  def check_page_title(title)
    expect(find_by_testid('page-heading')).to have_content(title)

    # Ensure pages are loaded before doing the next check
    wait_for_requests
  end
end
