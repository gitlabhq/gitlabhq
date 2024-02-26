# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User uses search filters', :js, feature_category: :global_search do
  include ListboxHelpers
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

      find_by_testid('group-filter').click

      wait_for_requests

      within_testid('group-filter') do
        select_listbox_item group.name
      end

      expect(find_by_testid('group-filter')).to have_content(group.name)

      find_by_testid('project-filter').click

      wait_for_requests

      within_testid('project-filter') do
        select_listbox_item group_project.name
      end

      expect(find_by_testid('project-filter')).to have_content(group_project.name)
    end

    context 'when the group filter is set' do
      before do
        visit search_path(search: "test", group_id: group.id, project_id: project.id)
      end

      describe 'clear filter button' do
        it 'removes Group and Project filters' do
          within_testid 'group-filter' do
            toggle_listbox
            wait_for_requests

            find_by_testid('listbox-reset-button').click

            wait_for_requests

            expect(page).to have_current_path(search_path, ignore_query: true) do |uri|
              uri.normalized_query(:sorted) == "scope=blobs&search=test"
            end
          end
        end
      end
    end
  end

  context 'when filtering by project' do
    it 'shows a project' do
      visit search_path

      find_by_testid('project-filter').click

      wait_for_requests

      within_testid('project-filter') do
        select_listbox_item project.name
      end

      expect(find_by_testid('project-filter')).to have_content(project.name)
    end

    context 'when the project filter is set' do
      before do
        visit search_path(search: "test", project_id: project.id)
      end

      let(:query) { { project_id: project.id } }

      describe 'clear filter button' do
        it 'removes Project filters' do
          within_testid 'project-filter' do
            toggle_listbox
            wait_for_requests

            find_by_testid('listbox-reset-button').click

            wait_for_requests

            expect(page).to have_current_path(search_path, ignore_query: true) do |uri|
              uri.normalized_query(:sorted) == "scope=blobs&search=test"
            end
          end
        end
      end
    end
  end
end
