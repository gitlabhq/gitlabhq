require 'spec_helper'

describe "Projects" do
  before do
    login_as :user
    @project = FactoryGirl.create :project, name: "GitLab / gitlab-shell"
  end

  describe "GET /projects", js: true do
    before do
      stub_js_gitlab_calls
      visit projects_path
    end

    it { page.should have_content "GitLab / gitlab-shell" }
    it { page.should have_selector ".search input#search" }
  end

  describe "GET /projects/:id" do
    before do
      visit project_path(@project)
    end

    it { page.should have_content @project.name }
    it { page.should have_content 'All commits' }
  end

  describe "GET /projects/:id/edit" do
    before do
      visit edit_project_path(@project)
    end

    it { page.should have_content @project.name }
    it { page.should have_content 'Build Schedule' }

    it "updates configuration" do
      fill_in 'Timeout', with: '70'
      click_button 'Save changes'

      page.should have_content 'was successfully updated'

      find_field('Timeout').value.should eq '70'
    end
  end

  describe "GET /projects/:id/charts" do
    before do
      visit project_charts_path(@project)
    end

    it { page.should have_content 'Overall' }
    it { page.should have_content 'Builds chart for last week' }
    it { page.should have_content 'Builds chart for last month' }
    it { page.should have_content 'Builds chart for last year' }
    it { page.should have_content 'Commit duration in minutes for last 30 commits' }
  end
end
