# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Prioritize labels', feature_category: :team_planning do
  include DragTo

  let(:user)     { create(:user) }
  let(:group)    { create(:group) }
  let(:project)  { create(:project, :public, namespace: group) }
  let!(:bug)     { create(:label, project: project, title: 'bug') }
  let!(:wontfix) { create(:label, project: project, title: 'wontfix') }
  let!(:feature) { create(:group_label, group: group, title: 'feature') }

  context 'when user belongs to project team' do
    before do
      project.add_developer(user)

      sign_in user
    end

    it 'user can prioritize a group label', :js do
      visit project_labels_path(project)

      expect(page).to have_content('Star labels to start sorting by priority')

      page.within('.other-labels') do
        all('.js-toggle-priority')[1].click
        wait_for_requests
        expect(page).not_to have_content('feature')
      end

      page.within('.prioritized-labels') do
        expect(page).not_to have_content('Star labels to start sorting by priority')
        expect(page).to have_content('feature')
      end
    end

    it 'user can unprioritize a group label', :js do
      create(:label_priority, project: project, label: feature, priority: 1)

      visit project_labels_path(project)

      page.within('.prioritized-labels') do
        expect(page).to have_content('feature')

        first('.js-toggle-priority').click
        wait_for_requests
        expect(page).not_to have_content('bug')
      end

      page.within('.other-labels') do
        expect(page).to have_content('feature')
      end
    end

    it 'user can prioritize a project label', :js do
      visit project_labels_path(project)

      expect(page).to have_content('Star labels to start sorting by priority')

      page.within('.other-labels') do
        first('.js-toggle-priority').click
        wait_for_requests
        expect(page).not_to have_content('bug')
      end

      page.within('.prioritized-labels') do
        expect(page).not_to have_content('Star labels to start sorting by priority')
        expect(page).to have_content('bug')
      end
    end

    it 'user can unprioritize a project label', :js do
      create(:label_priority, project: project, label: bug, priority: 1)

      visit project_labels_path(project)

      page.within('.prioritized-labels') do
        expect(page).to have_content('bug')

        first('.js-toggle-priority').click
        wait_for_requests
        expect(page).not_to have_content('bug')
      end

      page.within('.other-labels') do
        expect(page).to have_content('bug')
        expect(page).to have_content('wontfix')
      end
    end

    it 'user can sort prioritized labels and persist across reloads', :js do
      create(:label_priority, project: project, label: bug, priority: 1)
      create(:label_priority, project: project, label: feature, priority: 2)

      visit project_labels_path(project)

      expect(page).to have_content 'bug'
      expect(page).to have_content 'feature'
      expect(page).to have_content 'wontfix'

      # Sort labels
      drag_to(selector: '.js-label-list-item .label-content', from_index: 1, to_index: 2)

      page.within('.prioritized-labels') do
        expect(first('.js-label-list-item')).to have_content('feature')
        expect(page.all('.js-label-list-item').last).to have_content('bug')
      end

      refresh
      wait_for_requests

      page.within('.prioritized-labels') do
        expect(first('.js-label-list-item')).to have_content('feature')
        expect(page.all('.js-label-list-item').last).to have_content('bug')
      end
    end

    it 'user can see a primary button when there are only prioritized labels', :js do
      visit project_labels_path(project)

      page.within('.other-labels') do
        all('.js-toggle-priority').each do |el|
          el.click
        end
        wait_for_requests
      end

      page.within('.top-area') do
        expect(page).to have_link('New label')
      end
    end

    it 'shows a help message about prioritized labels' do
      visit project_labels_path(project)

      expect(page).to have_content 'Star a label'
    end
  end

  context 'as a guest' do
    before do
      create(:label_priority, project: project, label: bug, priority: 1)
      create(:label_priority, project: project, label: feature, priority: 2)

      guest = create(:user)

      sign_in guest

      visit project_labels_path(project)
    end

    it 'cannot prioritize labels' do
      expect(page).to have_content 'bug'
      expect(page).to have_content 'wontfix'
      expect(page).to have_content 'feature'
      expect(page).not_to have_content 'Star a label'
    end

    it 'cannot sort prioritized labels', :js do
      drag_to(selector: '.prioritized-labels .js-label-list-item', from_index: 1, to_index: 2)

      page.within('.prioritized-labels') do
        expect(first('.js-label-list-item')).to have_content('bug')
        expect(page.all('.js-label-list-item').last).to have_content('feature')
      end
    end
  end

  context 'as a non signed in user' do
    it 'cannot prioritize labels' do
      visit project_labels_path(project)

      expect(page).to have_content 'bug'
      expect(page).to have_content 'wontfix'
      expect(page).to have_content 'feature'
      expect(page).not_to have_content 'Star a label'
    end
  end
end
