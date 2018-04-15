require 'spec_helper'

feature 'Dashboard Projects' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, name: 'awesome stuff') }
  let(:project2) { create(:project, :public, name: 'Community project') }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  it_behaves_like "an autodiscoverable RSS feed with current_user's RSS token" do
    before do
      visit dashboard_projects_path
    end
  end

  it 'shows the project the user in a member of in the list' do
    visit dashboard_projects_path
    expect(page).to have_content('awesome stuff')
  end

  it 'shows "New project" button' do
    visit dashboard_projects_path

    page.within '#content-body' do
      expect(page).to have_link('New project')
    end
  end

  context 'when last_repository_updated_at, last_activity_at and update_at are present' do
    it 'shows the last_repository_updated_at attribute as the update date' do
      project.update_attributes!(last_repository_updated_at: Time.now, last_activity_at: 1.hour.ago)

      visit dashboard_projects_path

      expect(page).to have_xpath("//time[@datetime='#{project.last_repository_updated_at.getutc.iso8601}']")
    end

    it 'shows the last_activity_at attribute as the update date' do
      project.update_attributes!(last_repository_updated_at: 1.hour.ago, last_activity_at: Time.now)

      visit dashboard_projects_path

      expect(page).to have_xpath("//time[@datetime='#{project.last_activity_at.getutc.iso8601}']")
    end
  end

  context 'when last_repository_updated_at and last_activity_at are missing' do
    it 'shows the updated_at attribute as the update date' do
      project.update_attributes!(last_repository_updated_at: nil, last_activity_at: nil)
      project.touch

      visit dashboard_projects_path

      expect(page).to have_xpath("//time[@datetime='#{project.updated_at.getutc.iso8601}']")
    end
  end

  context 'when on Your projects tab' do
    it 'shows all projects by default' do
      visit dashboard_projects_path

      expect(page).to have_content(project.name)
    end

    it 'shows personal projects on personal projects tab', :js do
      project3 = create(:project, namespace: user.namespace)

      visit dashboard_projects_path

      click_link 'Personal'

      expect(page).not_to have_content(project.name)
      expect(page).to have_content(project3.name)
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

  describe 'with a pipeline', :clean_gitlab_redis_shared_state do
    let(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit.sha, ref: project.default_branch) }

    before do
      # Since the cache isn't updated when a new pipeline is created
      # we need the pipeline to advance in the pipeline since the cache was created
      # by visiting the login page.
      pipeline.succeed
    end

    it 'shows that the last pipeline passed' do
      visit dashboard_projects_path

      page.within('.controls') do
        expect(page).to have_xpath("//a[@href='#{pipelines_project_commit_path(project, project.commit, ref: pipeline.ref)}']")
        expect(page).to have_css('.ci-status-link')
        expect(page).to have_css('.ci-status-icon-success')
        expect(page).to have_link('Commit: passed')
      end
    end
  end

  context 'last push widget', :use_clean_rails_memory_store_caching do
    before do
      event = create(:push_event, project: project, author: user)

      create(:push_event_payload, event: event, ref: 'feature', action: :created)

      Users::LastPushEventService.new(user).cache_last_push_event(event)

      visit dashboard_projects_path
    end

    scenario 'shows "Create merge request" button' do
      expect(page).to have_content 'You pushed to feature'

      within('#content-body') do
        find_link('Create merge request', visible: false).click
      end

      expect(page).to have_selector('.merge-request-form')
      expect(current_path).to eq project_new_merge_request_path(project)
      expect(find('#merge_request_target_project_id', visible: false).value).to eq project.id.to_s
      expect(find('input#merge_request_source_branch', visible: false).value).to eq 'feature'
      expect(find('input#merge_request_target_branch', visible: false).value).to eq 'master'
    end
  end
end
