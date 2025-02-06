# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard Projects', :js, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :repository, creator: build(:user)) } # ensure creator != owner to avoid N+1 false-positive
  let_it_be(:project2) { create(:project, :public) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  context 'when feature :your_work_projects_vue is enabled' do
    let_it_be(:personal_project) { create(:project, namespace: user.namespace) }
    let_it_be(:personal_project_with_stars) { create(:project, namespace: user.namespace, star_count: 10) }
    let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project, sha: project.commit.sha, ref: project.default_branch) }

    it 'mounts JS app and defaults to contributed tab' do
      visit dashboard_projects_path
      wait_for_requests

      expect(page).to have_content('Projects')
      expect(page).to have_selector('a[aria-selected="true"]', text: 'Contributed')
    end

    it_behaves_like "an autodiscoverable RSS feed with current_user's feed token" do
      before do
        visit dashboard_projects_path
        wait_for_requests
      end
    end

    it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :dashboard_projects_path, :projects

    it 'links to the "Explore projects" page' do
      visit dashboard_projects_path
      wait_for_requests

      expect(page).to have_link("Explore projects", href: starred_explore_projects_path)
    end

    context 'when user has access to the project' do
      it 'shows role badge' do
        visit member_dashboard_projects_path
        wait_for_requests

        within_testid("projects-list-item-#{project.id}") do
          expect(find_by_testid('user-access-role')).to have_content('Developer')
        end
      end
    end

    context 'when last_activity_at and update_at are present', time_travel_to: '2025-01-27T09:44:07Z' do
      let_it_be(:project_with_last_activity) do
        create(
          :project,
          namespace: user.namespace,
          last_repository_updated_at: 1.hour.ago,
          last_activity_at: Time.current
        )
      end

      it 'shows the last_activity_at attribute as the update date', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/514342' do
        visit member_dashboard_projects_path
        wait_for_requests

        within_testid("projects-list-item-#{project_with_last_activity.id}") do
          expect(page).to have_xpath("//time[@datetime='#{project_with_last_activity.last_activity_at.iso8601}']")
        end
      end
    end

    context 'when last_activity_at is missing', time_travel_to: '2025-01-27T09:44:07Z' do
      it 'shows the updated_at attribute as the update date' do
        visit member_dashboard_projects_path
        wait_for_requests

        within_testid("projects-list-item-#{project.id}") do
          expect(page).to have_xpath("//time[@datetime='#{project.updated_at.iso8601}']")
        end
      end
    end

    it 'shows personal projects on personal projects tab' do
      visit personal_dashboard_projects_path
      wait_for_requests

      expect(page).not_to have_content(project.name)
      expect(page).to have_content(personal_project.name)
    end

    it 'sorts projects by most stars when sorting by most stars' do
      visit personal_dashboard_projects_path(sort: :stars_desc)
      wait_for_requests

      expect(first('[data-testid*="projects-list-item"]')).to have_content(personal_project_with_stars.title)
    end

    context 'when on Member projects tab' do
      it 'shows all projects you are a member of' do
        visit member_dashboard_projects_path
        wait_for_requests

        expect(page).to have_content(project.name)
        expect(page).to have_content(personal_project.name)
        expect(page).to have_content(personal_project_with_stars.name)
        expect(find('a[aria-selected="true"]')).to have_content('3')
      end
    end

    context 'when on Starred projects tab' do
      it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :starred_dashboard_projects_path, :projects

      it 'shows the empty state when there are no starred projects' do
        visit(starred_dashboard_projects_path)
        wait_for_requests

        expect(page).to have_text("You haven't starred any projects yet.")
      end

      it 'shows only starred projects' do
        user.toggle_star(project2)

        visit(starred_dashboard_projects_path)
        wait_for_requests

        expect(page).not_to have_content(project.name)
        expect(page).to have_content(project2.name)
        expect(find('a[aria-selected="true"]')).to have_content('1')
      end
    end

    describe 'with a pipeline' do
      it 'shows that the last pipeline passed' do
        visit member_dashboard_projects_path
        wait_for_requests

        within_testid("projects-list-item-#{project.id}") do
          expect(page).to have_css("[data-testid='ci-icon']")
          expect(page).to have_css('[data-testid="status_success_borderless-icon"]')
          expect(page).to have_link('Status: Passed')
        end
      end

      context 'guest user of project and project has private pipelines' do
        let_it_be(:guest_user) { create(:user) }
        let_it_be(:project_with_private_pipelines) { create(:project, namespace: user.namespace, public_builds: false) }

        before_all do
          project_with_private_pipelines.add_guest(guest_user)
        end

        before do
          sign_in(guest_user)
        end

        it 'does not show the pipeline status' do
          visit member_dashboard_projects_path
          wait_for_requests

          within_testid("projects-list-item-#{project_with_private_pipelines.id}") do
            expect(page).not_to have_css("[data-testid='ci-icon']")
          end
        end
      end

      context "when last_pipeline is missing" do
        it 'does not show the pipeline status' do
          visit member_dashboard_projects_path
          wait_for_requests

          within_testid("projects-list-item-#{personal_project.id}") do
            expect(page).not_to have_css("[data-testid='ci-icon']")
          end
        end
      end
    end

    context 'when project has topics' do
      let_it_be(:project_with_topics) { create(:project, namespace: user.namespace, topic_list: 'topic1') }

      it 'shows project topics' do
        visit member_dashboard_projects_path
        wait_for_requests

        within_testid("projects-list-item-#{project_with_topics.id}") do
          expect(page).to have_link('topic1', href: topic_explore_projects_path(topic_name: 'topic1'))
        end
      end
    end

    context 'when project does not have topics' do
      it 'does not show project topics' do
        visit member_dashboard_projects_path
        wait_for_requests

        within_testid("projects-list-item-#{project.id}") do
          expect(page).not_to have_selector('[data-testid="project-topics"]')
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

      it 'shows "Create merge request" button' do
        expect(page).to have_content 'You pushed to feature'

        within('#content-body') do
          find_link('Create merge request', visible: false).click
        end

        expect(page).to have_selector('.merge-request-form')
        expect(page).to have_current_path project_new_merge_request_path(project), ignore_query: true
        expect(find('#merge_request_target_project_id', visible: false).value).to eq project.id.to_s
        expect(page).to have_content "From feature into master"
      end
    end

    it 'avoids an N+1 query in dashboard index' do
      visit member_dashboard_projects_path
      wait_for_requests

      control = ActiveRecord::QueryRecorder.new do
        visit member_dashboard_projects_path
        wait_for_requests
      end

      new_project = create(:project, :repository, name: 'new project')
      create(:ci_pipeline, :with_job, status: :success, project: new_project, ref: new_project.commit.sha)
      new_project.add_developer(user)

      # There are a few known N+1 queries: https://gitlab.com/gitlab-org/gitlab/-/issues/214037
      # - User#max_member_access_for_project_ids
      # - ProjectsHelper#load_pipeline_status / Ci::CommitWithPipeline#last_pipeline
      # - Ci::Pipeline#detailed_status

      expect do
        visit member_dashboard_projects_path
        wait_for_requests
      end.not_to exceed_query_limit(control).with_threshold(4)
    end
  end

  context 'when feature :your_work_projects_vue is disabled' do
    before do
      stub_feature_flags(your_work_projects_vue: false)
    end

    it 'does not mount JS app' do
      visit dashboard_projects_path

      expect(page).to have_content('Projects')
      expect(page).not_to have_content('Active tab')
    end

    it_behaves_like "an autodiscoverable RSS feed with current_user's feed token" do
      before do
        visit dashboard_projects_path
      end
    end

    it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :dashboard_projects_path, :projects

    it 'links to the "Explore projects" page' do
      visit dashboard_projects_path

      expect(page).to have_link("Explore projects", href: starred_explore_projects_path)
    end

    context 'when user has access to the project' do
      it 'shows role badge' do
        visit dashboard_projects_path

        within_testid('user-access-role') do
          expect(page).to have_content('Developer')
        end
      end

      context 'when role changes', :use_clean_rails_memory_store_fragment_caching do
        it 'displays the right role' do
          visit dashboard_projects_path

          within_testid('user-access-role') do
            expect(page).to have_content('Developer')
          end

          project.members.last.update!(access_level: 40)

          visit dashboard_projects_path

          within_testid('user-access-role') do
            expect(page).to have_content('Maintainer')
          end
        end
      end
    end

    context 'when last_activity_at and update_at are present' do
      it 'shows the last_activity_at attribute as the update date' do
        project.update!(last_repository_updated_at: 1.hour.ago, last_activity_at: Time.zone.now)

        visit dashboard_projects_path

        expect(page).to have_xpath("//time[@datetime='#{project.last_activity_at.getutc.iso8601}']")
      end
    end

    context 'when last_activity_at is missing' do
      it 'shows the updated_at attribute as the update date' do
        project.update!(last_activity_at: nil)
        project.touch

        visit dashboard_projects_path

        expect(page).to have_xpath("//time[@datetime='#{project.updated_at.getutc.iso8601}']")
      end
    end

    context 'when on Your projects tab' do
      it 'shows all projects by default' do
        visit dashboard_projects_path

        expect(page).to have_content(project.name)
        expect(find('.gl-tabs-nav li:nth-child(1) .badge-pill')).to have_content(1)
      end

      it 'shows personal projects on personal projects tab' do
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
    end

    context 'when on Starred projects tab' do
      it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :starred_dashboard_projects_path, :projects

      it 'shows the empty state when there are no starred projects' do
        visit(starred_dashboard_projects_path)

        expect(page).to have_text(s_("StarredProjectsEmptyState|You don't have starred projects yet."))
      end

      it 'shows only starred projects' do
        user.toggle_star(project2)

        visit(starred_dashboard_projects_path)

        expect(page).not_to have_content(project.name)
        expect(page).to have_content(project2.name)
        expect(find('.gl-tabs-nav li:nth-child(1) .badge-pill')).to have_content(1)
        expect(find('.gl-tabs-nav li:nth-child(2) .badge-pill')).to have_content(1)
      end
    end

    describe 'with a pipeline', :clean_gitlab_redis_shared_state do
      let!(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit.sha, ref: project.default_branch) }

      before do
        # Since the cache isn't updated when a new pipeline is created
        # we need the pipeline to advance in the pipeline since the cache was created
        # by visiting the login page.
        pipeline.succeed
      end

      it 'shows that the last pipeline passed' do
        visit dashboard_projects_path

        within_testid('project_controls') do
          expect(page).to have_xpath("//a[@href='#{pipelines_project_commit_path(project, project.commit, ref: pipeline.ref)}']")
          expect(page).to have_css("[data-testid='ci-icon']")
          expect(page).to have_css('[data-testid="status_success_borderless-icon"]')
          expect(page).to have_link('Pipeline: passed')
        end
      end

      shared_examples 'hidden pipeline status' do
        it 'does not show the pipeline status' do
          visit dashboard_projects_path

          within_testid('project_controls') do
            expect(page).not_to have_xpath("//a[@href='#{pipelines_project_commit_path(project, project.commit, ref: pipeline.ref)}']")
            expect(page).not_to have_css("[data-testid='ci-icon']")
            expect(page).not_to have_css('[data-testid="status_success_borderless-icon"]')
            expect(page).not_to have_link('Pipeline: passed')
          end
        end
      end

      context 'guest user of project and project has private pipelines' do
        let(:guest_user) { create(:user) }

        before do
          project.update!(public_builds: false)
          project.add_guest(guest_user)
          sign_in(guest_user)
        end

        it_behaves_like 'hidden pipeline status'
      end

      context "when last_pipeline is missing" do
        before do
          project.last_pipeline.delete
        end

        it_behaves_like 'hidden pipeline status'
      end
    end

    describe 'with topics' do
      context 'when project has topics' do
        before do
          project.update_attribute(:topic_list, 'topic1')
        end

        it 'shows project topics if exist' do
          visit dashboard_projects_path

          expect(page).to have_selector('[data-testid="project_topic_list"]')
          expect(page).to have_link('topic1', href: topic_explore_projects_path(topic_name: 'topic1'))
        end
      end

      context 'when project does not have topics' do
        it 'does not show project topics' do
          visit dashboard_projects_path

          expect(page).not_to have_selector('[data-testid="project_topic_list"]')
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

      it 'shows "Create merge request" button' do
        expect(page).to have_content 'You pushed to feature'

        within('#content-body') do
          find_link('Create merge request', visible: false).click
        end

        expect(page).to have_selector('.merge-request-form')
        expect(page).to have_current_path project_new_merge_request_path(project), ignore_query: true
        expect(find('#merge_request_target_project_id', visible: false).value).to eq project.id.to_s
        expect(page).to have_content "From feature into master"
      end
    end

    it 'avoids an N+1 query in dashboard index' do
      create(:ci_pipeline, :with_job, status: :success, project: project, ref: project.default_branch, sha: project.commit.sha)
      visit dashboard_projects_path

      control = ActiveRecord::QueryRecorder.new { visit dashboard_projects_path }

      new_project = create(:project, :repository, name: 'new project')
      create(:ci_pipeline, :with_job, status: :success, project: new_project, ref: new_project.commit.sha)
      new_project.add_developer(user)

      ActiveRecord::QueryRecorder.new { visit dashboard_projects_path }.count

      # There are a few known N+1 queries: https://gitlab.com/gitlab-org/gitlab/-/issues/214037
      # - User#max_member_access_for_project_ids
      # - ProjectsHelper#load_pipeline_status / Ci::CommitWithPipeline#last_pipeline
      # - Ci::Pipeline#detailed_status

      expect { visit dashboard_projects_path }.not_to exceed_query_limit(control).with_threshold(4)
    end
  end
end
