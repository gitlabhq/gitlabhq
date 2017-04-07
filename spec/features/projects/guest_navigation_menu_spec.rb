require 'spec_helper'

describe "Guest navigation menu" do
  let(:project) { create(:empty_project, :private, public_builds: false) }
  let(:guest) { create(:user) }

  before do
    project.team << [guest, :guest]

    login_as(guest)
  end

  it "shows allowed tabs only" do
    visit namespace_project_path(project.namespace, project)

    within(".layout-nav") do
      expect(page).to have_content 'Project'
      expect(page).to have_content 'Issues'
      expect(page).to have_content 'Wiki'

      expect(page).not_to have_content 'Repository'
      expect(page).not_to have_content 'Pipelines'
      expect(page).not_to have_content 'Merge Requests'
    end
  end

  it "does not show fork button" do
    visit namespace_project_path(project.namespace, project)

    within(".count-buttons") do
      expect(page).not_to have_link 'Fork'
    end
  end

  it "does not show clone path" do
    visit namespace_project_path(project.namespace, project)

    within(".project-repo-buttons") do
      expect(page).not_to have_selector '.project-clone-holder'
    end
  end

  describe 'project landing page' do
    before do
      project.project_feature.update_attribute("issues_access_level", ProjectFeature::DISABLED)
      project.project_feature.update_attribute("wiki_access_level", ProjectFeature::DISABLED)
    end

    it "does not show the project file list landing page" do
      visit namespace_project_path(project.namespace, project)
      expect(page).not_to have_selector '.project-stats'
      expect(page).not_to have_selector '.project-last-commit'
      expect(page).not_to have_selector '.project-show-files'
    end

    it "shows the customize workflow when issues and wiki are disabled" do
      visit namespace_project_path(project.namespace, project)
      expect(page).to have_selector '.project-show-customize_workflow'
    end

    it "shows the wiki when enabled" do
      project.project_feature.update_attribute("wiki_access_level", ProjectFeature::PRIVATE)
      visit namespace_project_path(project.namespace, project)
      expect(page).to have_selector '.project-show-wiki'
    end

    it "shows the issues when enabled" do
      project.project_feature.update_attribute("issues_access_level", ProjectFeature::PRIVATE)
      visit namespace_project_path(project.namespace, project)
      expect(page).to have_selector '.issues-list'
    end
  end
end
