require 'spec_helper'

RSpec.describe 'Dashboard Projects', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: "awesome stuff") }

  before do
    project.team << [user, :developer]
    login_as user
  end

  it 'shows the project the user in a member of in the list' do
    visit dashboard_projects_path
    expect(page).to have_content('awesome stuff')
  end

  describe "with a pipeline", redis: true do
    let!(:pipeline) {  create(:ci_pipeline, project: project, sha: project.commit.sha) }

    before do
      # Since the cache isn't updated when a new pipeline is created
      # we need the pipeline to advance in the pipeline since the cache was created
      # by visiting the login page.
      pipeline.succeed
    end

    it 'shows that the last pipeline passed' do
      visit dashboard_projects_path

      expect(page).to have_xpath("//a[@href='#{pipelines_namespace_project_commit_path(project.namespace, project, project.commit)}']")
    end
  end

  it_behaves_like "an autodiscoverable RSS feed with current_user's private token"
end
