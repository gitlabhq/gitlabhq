require 'rails_helper'

describe 'Filter issues', feature: true do

  let!(:project)   { create(:project) }
  let!(:issue)     { create(:issue, project: project) }
  let!(:user)      { create(:user)}

  before do
    project.team << [user, :master]
    login_as(user)
  end

  describe 'Filter issues for assignee from issues#index' do

    before do
      visit namespace_project_issues_path(project.namespace, project)

      find('.js-assignee-search').click

      find('.dropdown-menu-user-link', text: user.username).click

      sleep 2
    end

    context 'assignee', js: true do
      it 'should update to current user' do
        expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
      end

      it 'should not change when closed link is clicked' do
        find('.issues-state-filters a', text: "Closed").click

        expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
      end


      it 'should not change when all link is clicked' do
        find('.issues-state-filters a', text: "All").click

        expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
      end
    end
  end
end
