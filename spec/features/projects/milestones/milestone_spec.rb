require 'spec_helper'

feature 'Project milestone', :feature do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project, name: 'test', namespace: user.namespace) }
  let(:milestone) { create(:milestone, project: project) }

  before do
    login_as(user)
  end

  context 'when project has enabled issues' do
    before do
      visit namespace_project_milestone_path(project.namespace, project, milestone)
    end

    it 'shows issues tab' do
      within('#content-body') do
        expect(page).to have_link 'Issues', href: '#tab-issues'
        expect(page).to have_selector '.nav-links li.active', count: 1
        expect(find('.nav-links li.active')).to have_content 'Issues'
      end
    end

    it 'shows issues stats' do
      expect(page).to have_content 'issues:'
    end

    it 'shows Browse Issues button' do
      within('#content-body') do
        expect(page).to have_link 'Browse Issues'
      end
    end
  end

  context 'when project has disabled issues' do
    before do
      project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)
      visit namespace_project_milestone_path(project.namespace, project, milestone)
    end

    it 'hides issues tab' do
      within('#content-body') do
        expect(page).not_to have_link 'Issues', href: '#tab-issues'
        expect(page).to have_selector '.nav-links li.active', count: 1
        expect(find('.nav-links li.active')).to have_content 'Merge Requests'
      end
    end

    it 'hides issues stats' do
      expect(page).to have_no_content 'issues:'
    end

    it 'hides Browse Issues button' do
      within('#content-body') do
        expect(page).not_to have_link 'Browse Issues'
      end
    end

    it 'does not show an informative message' do
      expect(page).not_to have_content('Assign some issues to this milestone.')
    end
  end
end
