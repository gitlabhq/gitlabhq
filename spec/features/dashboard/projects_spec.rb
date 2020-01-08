# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard Projects' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, name: 'awesome stuff') }
  let(:project2) { create(:project, :public, name: 'Community project') }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  it_behaves_like "an autodiscoverable RSS feed with current_user's feed token" do
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

  context 'when user has access to the project' do
    it 'shows role badge' do
      visit dashboard_projects_path

      page.within '.user-access-role' do
        expect(page).to have_content('Developer')
      end
    end

    context 'when role changes', :use_clean_rails_memory_store_fragment_caching do
      it 'displays the right role' do
        visit dashboard_projects_path

        page.within '.user-access-role' do
          expect(page).to have_content('Developer')
        end

        project.members.last.update(access_level: 40)

        visit dashboard_projects_path

        page.within '.user-access-role' do
          expect(page).to have_content('Maintainer')
        end
      end
    end
  end

  context 'when last_repository_updated_at, last_activity_at and update_at are present' do
    it 'shows the last_repository_updated_at attribute as the update date' do
      project.update!(last_repository_updated_at: Time.now, last_activity_at: 1.hour.ago)

      visit dashboard_projects_path

      expect(page).to have_xpath("//time[@datetime='#{project.last_repository_updated_at.getutc.iso8601}']")
    end

    it 'shows the last_activity_at attribute as the update date' do
      project.update!(last_repository_updated_at: 1.hour.ago, last_activity_at: Time.now)

      visit dashboard_projects_path

      expect(page).to have_xpath("//time[@datetime='#{project.last_activity_at.getutc.iso8601}']")
    end
  end

  context 'when last_repository_updated_at and last_activity_at are missing' do
    it 'shows the updated_at attribute as the update date' do
      project.update!(last_repository_updated_at: nil, last_activity_at: nil)
      project.touch

      visit dashboard_projects_path

      expect(page).to have_xpath("//time[@datetime='#{project.updated_at.getutc.iso8601}']")
    end
  end

  context 'when on Your projects tab' do
    it 'shows all projects by default' do
      visit dashboard_projects_path

      expect(page).to have_content(project.name)
      expect(find('.nav-links li:nth-child(1) .badge-pill')).to have_content(1)
    end

    it 'shows personal projects on personal projects tab', :js do
      project3 = create(:project, namespace: user.namespace)

      visit dashboard_projects_path

      click_link 'Personal'

      expect(page).not_to have_content(project.name)
      expect(page).to have_content(project3.name)
    end

    it 'sorts projects by most stars when sorting by most stars' do
      project_with_most_stars = create(:project, namespace: user.namespace, star_count: 10)

      visit dashboard_projects_path(sort: :stars_desc)

      expect(first('.project-row')).to have_content(project_with_most_stars.title)
    end

    it 'shows tabs to filter by all projects or personal' do
      visit dashboard_projects_path
      segmented_button = page.find('.filtered-search-nav .button-filter-group')

      expect(segmented_button).to have_content 'All'
      expect(segmented_button).to have_content 'Personal'
    end
  end

  context 'when on Starred projects tab', :js do
    it 'shows the empty state when there are no starred projects' do
      visit(starred_dashboard_projects_path)

      element = page.find('.row.empty-state')

      expect(element).to have_content("You don't have starred projects yet.")
      expect(element.find('.svg-content img')['src']).to have_content('illustrations/starred_empty')
    end

    it 'shows only starred projects' do
      user.toggle_star(project2)

      visit(starred_dashboard_projects_path)

      expect(page).not_to have_content(project.name)
      expect(page).to have_content(project2.name)
      expect(find('.nav-links li:nth-child(1) .badge-pill')).to have_content(1)
      expect(find('.nav-links li:nth-child(2) .badge-pill')).to have_content(1)
    end

    it 'does not show tabs to filter by all projects or personal' do
      visit(starred_dashboard_projects_path)

      expect(page).not_to have_content '.filtered-search-nav'
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
        expect(page).to have_link('Pipeline: passed')
      end
    end

    shared_examples 'hidden pipeline status' do
      it 'does not show the pipeline status' do
        visit dashboard_projects_path

        page.within('.controls') do
          expect(page).not_to have_xpath("//a[@href='#{pipelines_project_commit_path(project, project.commit, ref: pipeline.ref)}']")
          expect(page).not_to have_css('.ci-status-link')
          expect(page).not_to have_css('.ci-status-icon-success')
          expect(page).not_to have_link('Pipeline: passed')
        end
      end
    end

    context 'guest user of project and project has private pipelines' do
      let(:guest_user) { create(:user) }

      before do
        project.update(public_builds: false)
        project.add_guest(guest_user)
        sign_in(guest_user)
      end

      it_behaves_like 'hidden pipeline status'
    end

    context 'when dashboard_pipeline_status is disabled' do
      before do
        stub_feature_flags(dashboard_pipeline_status: false)
      end

      it_behaves_like 'hidden pipeline status'
    end
  end

  context 'last push widget', :use_clean_rails_memory_store_caching do
    before do
      event = create(:push_event, project: project, author: user)

      create(:push_event_payload, event: event, ref: 'feature', action: :created)

      Users::LastPushEventService.new(user).cache_last_push_event(event)

      visit dashboard_projects_path
    end

    it 'shows "Create merge request" button' do
      expect(page).to have_content 'You pushed to feature'

      within('#content-body') do
        find_link('Create merge request', visible: false).click
      end

      expect(page).to have_selector('.merge-request-form')
      expect(current_path).to eq project_new_merge_request_path(project)
      expect(find('#merge_request_target_project_id', visible: false).value).to eq project.id.to_s
      expect(page).to have_content "From feature into master"
    end
  end

  it 'avoids an N+1 query in dashboard index' do
    create(:ci_pipeline, :with_job, status: :success, project: project, ref: project.default_branch, sha: project.commit.sha)
    visit dashboard_projects_path

    control_count = ActiveRecord::QueryRecorder.new { visit dashboard_projects_path }.count

    new_project = create(:project, :repository, name: 'new project')
    create(:ci_pipeline, :with_job, status: :success, project: new_project, ref: new_project.commit.sha)
    new_project.add_developer(user)

    ActiveRecord::QueryRecorder.new { visit dashboard_projects_path }.count

    # There are three known N+1 queries:
    # 1. Project#open_issues_count
    # 2. Project#open_merge_requests_count
    # 3. Project#forks_count
    #
    # In addition, ProjectsHelper#load_pipeline_status also adds an
    # additional query.
    expect { visit dashboard_projects_path }.not_to exceed_query_limit(control_count + 4)
  end
end
