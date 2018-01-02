require 'spec_helper'

describe 'Guest navigation menu' do
  let(:project) { create(:project, :private, public_builds: false) }
  let(:guest) { create(:user) }

  before do
    project.add_guest(guest)

    sign_in(guest)
  end

  it 'shows allowed tabs only' do
    visit project_path(project)

    within('.nav-sidebar') do
      expect(page).to have_content 'Overview'
      expect(page).to have_content 'Issues'
      expect(page).to have_content 'Wiki'

      expect(page).not_to have_content 'Repository'
      expect(page).not_to have_content 'Pipelines'
      expect(page).not_to have_content 'Merge Requests'
    end
  end

  it 'does not show fork button' do
    visit project_path(project)

    within('.count-buttons') do
      expect(page).not_to have_link 'Fork'
    end
  end

  it 'does not show clone path' do
    visit project_path(project)

    within('.project-repo-buttons') do
      expect(page).not_to have_selector '.project-clone-holder'
    end
  end

  describe 'project landing page' do
    before do
      project.project_feature.update!(
        issues_access_level: ProjectFeature::DISABLED,
        wiki_access_level: ProjectFeature::DISABLED
      )
    end

    it 'does not show the project file list landing page' do
      visit project_path(project)

      expect(page).not_to have_selector '.project-stats'
      expect(page).not_to have_selector '.project-last-commit'
      expect(page).not_to have_selector '.project-show-files'
      expect(page).to have_selector '.project-show-customize_workflow'
    end

    it 'shows the customize workflow when issues and wiki are disabled' do
      visit project_path(project)

      expect(page).to have_selector '.project-show-customize_workflow'
    end

    it 'shows the wiki when enabled' do
      project.project_feature.update!(wiki_access_level: ProjectFeature::PRIVATE)

      visit project_path(project)

      expect(page).to have_selector '.project-show-wiki'
    end

    it 'shows the issues when enabled' do
      project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)

      visit project_path(project)

      expect(page).to have_selector '.issues-list'
    end
  end
end
