require 'spec_helper'

feature 'Prioritize labels', feature: true do
  include WaitForAjax

  context 'when project belongs to user' do
    let(:user)    { create(:user) }
    let(:project) { create(:project, name: 'test', namespace: user.namespace) }

    scenario 'user can prioritize a label', js: true do
      bug     = create(:label, title: 'bug')
      wontfix = create(:label, title: 'wontfix')

      project.labels << bug
      project.labels << wontfix

      login_as user
      visit namespace_project_labels_path(project.namespace, project)

      expect(page).to have_content('No prioritized labels yet')

      page.within('.other-labels') do
        first('.js-toggle-priority').click
        wait_for_ajax
        expect(page).not_to have_content('bug')
      end

      page.within('.prioritized-labels') do
        expect(page).not_to have_content('No prioritized labels yet')
        expect(page).to have_content('bug')
      end
    end

    scenario 'user can unprioritize a label', js: true do
      bug     = create(:label, title: 'bug', priority: 1)
      wontfix = create(:label, title: 'wontfix')

      project.labels << bug
      project.labels << wontfix

      login_as user
      visit namespace_project_labels_path(project.namespace, project)

      expect(page).to have_content('bug')

      page.within('.prioritized-labels') do
        first('.js-toggle-priority').click
        wait_for_ajax
        expect(page).not_to have_content('bug')
      end

      page.within('.other-labels') do
        expect(page).to have_content('bug')
        expect(page).to have_content('wontfix')
      end
    end

    scenario 'user can sort prioritized labels and persist across reloads', js: true do
      bug     = create(:label, title: 'bug', priority: 1)
      wontfix = create(:label, title: 'wontfix', priority: 2)

      project.labels << bug
      project.labels << wontfix

      login_as user
      visit namespace_project_labels_path(project.namespace, project)

      expect(page).to have_content 'bug'
      expect(page).to have_content 'wontfix'

      # Sort labels
      find("#label_#{bug.id}").drag_to find("#label_#{wontfix.id}")

      page.within('.prioritized-labels') do
        expect(first('li')).to have_content('wontfix')
        expect(page.all('li').last).to have_content('bug')
      end

      refresh
      wait_for_ajax

      page.within('.prioritized-labels') do
        expect(first('li')).to have_content('wontfix')
        expect(page.all('li').last).to have_content('bug')
      end
    end
  end

  context 'as a guest' do
    it 'can not prioritize labels' do
      user = create(:user)
      guest = create(:user)
      project = create(:project, name: 'test', namespace: user.namespace)

      create(:label, title: 'bug')

      login_as guest
      visit namespace_project_labels_path(project.namespace, project)

      expect(page).not_to have_css('.prioritized-labels')
    end
  end

  context 'as a non signed in user' do
    it 'can not prioritize labels' do
      user = create(:user)
      project = create(:project, name: 'test', namespace: user.namespace)

      create(:label, title: 'bug')

      visit namespace_project_labels_path(project.namespace, project)

      expect(page).not_to have_css('.prioritized-labels')
    end
  end
end
