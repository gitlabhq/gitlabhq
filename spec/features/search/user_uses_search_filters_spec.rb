require 'spec_helper'

describe 'User uses search filters', :js do
  let(:group) { create(:group) }
  let!(:group_project) { create(:project, group: group) }
  let(:project) { create(:project, namespace: user.namespace) }
  let(:user) { create(:user) }

  before do
    project.add_reporter(user)
    group.add_owner(user)
    sign_in(user)

    visit(search_path)
  end

  context' when filtering by group' do
    it 'shows group projects' do
      find('.js-search-group-dropdown').click

      wait_for_requests

      page.within('.search-holder') do
        click_link(group.name)
      end

      expect(find('.js-search-group-dropdown')).to have_content(group.name)

      page.within('.project-filter') do
        find('.js-search-project-dropdown').click

        wait_for_requests

        expect(page).to have_link(group_project.full_name)
      end
    end
  end

  context' when filtering by project' do
    it 'shows a project' do
      page.within('.project-filter') do
        find('.js-search-project-dropdown').click

        wait_for_requests

        click_link(project.full_name)
      end

      expect(find('.js-search-project-dropdown')).to have_content(project.full_name)
    end
  end
end
