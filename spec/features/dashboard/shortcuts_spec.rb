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

      find('body').send_keys([:shift, 'H'])

      check_page_title('Projects') # This will need to change when we remove the `personal_homepage` feature flag
    end
  end

  context 'logged out', :with_current_organization do
    before do
      visit explore_root_path
    end

    it 'navigates to pages' do
      find('body').send_keys([:shift, 'G'])

      expect(page).to have_content(s_('Groups|Browse groups to learn from and contribute to.'))

      find('body').send_keys([:shift, 'S'])

      expect(page).to have_content(s_('SnippetsEmptyState|There are no snippets found'))

      find('body').send_keys([:shift, 'P'])

      expect(page).to have_content(s_('Projects|Browse projects to learn from and contribute to.'))
    end

    context 'when `explore_projects_vue` flag is disabled' do
      it 'navigates to project page' do
        stub_feature_flags(explore_projects_vue: false)

        find('body').send_keys([:shift, 'P'])

        find('.nothing-here-block')
        expect(page).to have_content(s_('UserProfile|Explore public groups to find projects to contribute to'))
      end
    end

    context 'when `explore_groups_vue` flag is disabled' do
      before do
        stub_feature_flags(explore_groups_vue: false)
      end

      it 'navigates to explore groups page' do
        find('body').send_keys([:shift, 'G'])

        expect(page).to have_content(_('No public or internal groups'))
      end
    end
  end

  def check_page_title(title)
    expect(find_by_testid('page-heading')).to have_content(title)

    # Ensure pages are loaded before doing the next check
    wait_for_requests
  end
end
