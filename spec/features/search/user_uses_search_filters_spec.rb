# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User uses search filters', :js do
  let(:group) { create(:group) }
  let!(:group_project) { create(:project, group: group) }
  let(:project) { create(:project, namespace: user.namespace) }
  let(:user) { create(:user) }

  before do
    project.add_reporter(user)
    group.add_owner(user)
    sign_in(user)
  end

  context 'when filtering by group' do
    it 'shows group projects' do
      visit search_path

      find('[data-testid="group-filter"]').click

      wait_for_requests

      page.within('[data-testid="group-filter"]') do
        click_on(group.name)
      end

      expect(find('[data-testid="group-filter"]')).to have_content(group.name)

      find('[data-testid="project-filter"]').click

      wait_for_requests

      page.within('[data-testid="project-filter"]') do
        click_on(group_project.name)
      end

      expect(find('[data-testid="project-filter"]')).to have_content(group_project.name)
    end

    context 'when the group filter is set' do
      before do
        visit search_path(search: "test", group_id: group.id, project_id: project.id)
      end

      describe 'clear filter button' do
        it 'removes Group and Project filters' do
          find('[data-testid="group-filter"] [data-testid="clear-icon"]').click

          wait_for_requests

          expect(page).to have_current_path(search_path(search: "test"))
        end
      end
    end
  end

  context 'when filtering by project' do
    it 'shows a project' do
      visit search_path

      find('[data-testid="project-filter"]').click

      wait_for_requests

      page.within('[data-testid="project-filter"]') do
        click_on(project.name)
      end

      expect(find('[data-testid="project-filter"]')).to have_content(project.name)
    end

    context 'when the project filter is set' do
      before do
        visit search_path(search: "test", project_id: project.id)
      end

      let(:query) { { project_id: project.id } }

      describe 'clear filter button' do
        it 'removes Project filters' do
          find('[data-testid="project-filter"] [data-testid="clear-icon"]').click
          wait_for_requests

          expect(page).to have_current_path(search_path(search: "test"))
        end
      end
    end
  end
end
