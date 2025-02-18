# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > User interacts with project stars', feature_category: :groups_and_projects do
  let(:project) { create(:project, :public, :repository) }

  context 'when user is signed in', :js do
    let(:user) { create(:user) }

    before do
      stub_feature_flags(vscode_web_ide: false)
      sign_in(user)
      visit(project_path(project))
    end

    it 'retains the star count even after a page reload' do
      star_project

      reload_page

      expect(page).to have_css('.star-count', text: 1)
    end

    it 'toggles the star' do
      star_project

      expect(page).to have_css('.star-count', text: 1)

      unstar_project

      expect(page).to have_css('.star-count', text: 0)
    end

    context 'when feature flag your_work_projects_vue is enabled', :js do
      it 'validates starring a project' do
        project.add_owner(user)

        star_project

        visit(member_dashboard_projects_path)
        wait_for_requests

        expect(find_link('Stars')).to have_content('1')
      end

      it 'validates un-starring a project' do
        project.add_owner(user)

        star_project

        unstar_project

        visit(member_dashboard_projects_path)
        wait_for_requests

        expect(find_link('Stars')).to have_content('0')
      end
    end

    context 'when feature flag your_work_projects_vue is disabled' do
      before do
        stub_feature_flags(your_work_projects_vue: false)
      end

      it 'validates starring a project' do
        project.add_owner(user)

        star_project

        visit(dashboard_projects_path)

        expect(page).to have_css('.stars', text: 1)
      end

      it 'validates un-starring a project' do
        project.add_owner(user)

        star_project

        unstar_project

        visit(dashboard_projects_path)

        expect(page).to have_css('.stars', text: 0)
      end
    end
  end

  context 'when user is not signed in', :js do
    before do
      visit(project_path(project))
    end

    it 'does not allow to star a project' do
      expect(page).not_to have_content('.toggle-star')

      find('.star-btn').click

      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
    end
  end
end

private

def reload_page
  visit current_path
end

def star_project
  click_button(_('Star'))
  wait_for_requests
end

def unstar_project
  click_button(_('Unstar'))
  wait_for_requests
end
