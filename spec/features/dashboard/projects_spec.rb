require 'spec_helper'

RSpec.describe 'Dashboard Projects', feature: true, js: true do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:project) { create(:project, name: "awesome stuff") }
  let(:project2) { create(:project, :public, name: 'Community project', namespace: user2.namespace) }
  let(:archived_project) { create(:project, :archived) }

  before do
    project.team << [user, :developer]
    project2.team << [user, :developer]
    archived_project.team << [user, :developer]
    gitlab_sign_in(user)
  end

  describe 'displays projects in list' do
    it 'shows the projects the user is a member of' do
      visit dashboard_projects_path
      expect(page).to have_content(project.name)
    end

    it 'shows the last_activity_at attribute as the update date' do
      now = Time.now
      project.update_column(:last_activity_at, now)

      visit dashboard_projects_path

      expect(page).to have_xpath("//time[@datetime='#{now.getutc.iso8601}']")
    end
  end

  describe 'search and sort' do
    before do
      visit dashboard_projects_path
    end

    it 'filters by name' do
      expect(page).to have_content(project.name)
      expect(page).to have_content(project2.name)

      fill_in 'name', with: project.name

      expect(page).to have_content(project.name)
      expect(page).not_to have_content(project2.name)
    end

    it 'shows projects owned by anyone' do
      expect(page).to have_content(project.name)
      expect(page).to have_content(project2.name)
    end

    it 'shows projects owned by me' do
      select_from_sort_dropdown('Owned by me')

      expect(page).to have_content(project.name)
      expect(page).not_to have_content(project2.name)
    end

    it 'hides archived projects' do
      expect(page).not_to have_content(archived_project.name)
    end

    it 'shows archived projects' do
      select_from_sort_dropdown('Show archived projects')

      expect(page).to have_content(archived_project.name)
      expect(page).to have_css(".label-warning", text: 'archived')
    end

    it 'retains filter values when sorting' do
      fill_in 'name', with: project.name

      select_from_sort_dropdown('Show archived projects')

      expect(page).to have_content(project.name)
      expect(page).not_to have_content(project2.name)
    end

    def select_from_sort_dropdown(label_text)
      find('#sort-projects-dropdown').click()
      filter = "//li[contains(., '#{label_text}')]"

      find(:xpath, filter).click()
    end
  end

  context 'when on Starred projects tab' do
    it 'shows only starred projects' do
      user.toggle_star(project2)

      visit(starred_dashboard_projects_path)

      expect(page).not_to have_content(project.name)
      expect(page).to have_content(project2.name)
    end
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

  it_behaves_like "an autodiscoverable RSS feed with current_user's RSS token"
end
