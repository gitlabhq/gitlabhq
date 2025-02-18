# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipeline', :js, feature_category: :continuous_integration do
  include RoutesHelpers
  include ProjectForksHelper
  include ::ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project) }

  let(:user) { create(:user) }
  let(:role) { :developer }

  before do
    sign_in(user)
    project.add_role(user, role)
  end

  shared_context 'pipeline builds' do
    let!(:external_stage) { create(:ci_stage, name: 'external', pipeline: pipeline) }

    let!(:build_passed) do
      create(:ci_build, :success, pipeline: pipeline, stage: 'build', stage_idx: 0, name: 'build')
    end

    let!(:build_failed) do
      create(:ci_build, :failed, pipeline: pipeline, stage: 'test', stage_idx: 1, name: 'test')
    end

    let!(:build_preparing) do
      create(:ci_build, :preparing, pipeline: pipeline, stage: 'deploy', stage_idx: 2, name: 'prepare')
    end

    let!(:build_running) do
      create(:ci_build, :running, pipeline: pipeline, stage: 'deploy', stage_idx: 3, name: 'deploy')
    end

    let!(:build_manual) do
      create(:ci_build, :manual, pipeline: pipeline, stage: 'deploy', stage_idx: 3, name: 'manual-build')
    end

    let!(:build_scheduled) do
      create(:ci_build, :scheduled, pipeline: pipeline, stage: 'deploy', stage_idx: 3, name: 'delayed-job')
    end

    let!(:build_external) do
      create(
        :generic_commit_status,
        status: 'success',
        pipeline: pipeline,
        name: 'jenkins',
        ci_stage: external_stage,
        ref: 'master',
        target_url: 'http://gitlab.com/status'
      )
    end
  end

  describe 'GET /:project/-/pipelines/:id' do
    include_context 'pipeline builds'

    let_it_be(:group) { create(:group) }
    let_it_be(:project, reload: true) { create(:project, :repository, group: group) }

    let(:pipeline) do
      create(:ci_pipeline, name: 'Build pipeline', project: project, ref: 'master', sha: project.commit.id, user: user)
    end

    subject(:visit_pipeline) { visit project_pipeline_path(project, pipeline) }

    it 'shows the pipeline graph' do
      visit_pipeline

      expect(page).to have_selector('.js-pipeline-graph')
      expect(page).to have_content('build')
      expect(page).to have_content('test')
      expect(page).to have_content('deploy')
      expect(page).to have_content('Retry')
      expect(page).to have_content('Cancel pipeline')
    end

    it 'shows link to the pipeline ref' do
      visit_pipeline

      expect(page).to have_link(pipeline.ref)
    end

    it 'shows the pipeline information' do
      visit_pipeline

      within_testid 'pipeline-header' do
        expect(page).to have_content("For #{pipeline.ref}")
        expect(page).to have_content("#{pipeline.statuses.count} jobs")
        expect(page).to have_link(pipeline.ref,
          href: project_commits_path(pipeline.project, pipeline.ref))
      end
    end

    it 'displays pipeline name instead of commit title' do
      visit_pipeline

      within_testid 'pipeline-header' do
        expect(page).to have_content(pipeline.name)
        expect(page).to have_content(project.commit.short_id)
        expect(page).not_to have_selector('[data-testid="pipeline-commit-title"]')
      end
    end

    context 'without pipeline name' do
      let(:pipeline) do
        create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id, user: user)
      end

      it 'displays commit title' do
        visit_pipeline

        within_testid 'pipeline-header' do
          expect(page).to have_content(project.commit.title)
          expect(page).not_to have_selector('[data-testid="pipeline-name"]')
        end
      end
    end

    describe 'pipeline stats text' do
      let(:finished_pipeline) do
        create(:ci_pipeline, :success, project: project, ref: 'master', sha: project.commit.id, user: user)
      end

      before do
        finished_pipeline.update!(
          started_at: "2023-01-01 01:01:05",
          created_at: "2023-01-01 01:01:01",
          finished_at: "2023-01-01 01:01:10",
          duration: 9
        )
      end

      context 'pipeline has finished' do
        it 'shows time ago' do
          visit project_pipeline_path(project, finished_pipeline)

          within_testid 'pipeline-header' do
            expect(page).to have_selector('[data-testid="pipeline-finished-time-ago"]')
          end
        end
      end

      context 'pipeline has not finished' do
        it 'does not show time ago' do
          visit_pipeline

          within_testid 'pipeline-header' do
            expect(page).not_to have_selector('[data-testid="pipeline-finished-time-ago"]')
          end
        end
      end
    end

    describe 'pipeline graph' do
      context 'when pipeline has running builds' do
        before do
          visit_pipeline
        end

        it 'shows a running icon and a cancel action for the running build' do
          page.within('#ci-badge-deploy') do
            expect(page).to have_selector('[data-testid="status_running_borderless-icon"]')
            expect(page).to have_selector('.js-icon-cancel')
            expect(page).to have_content('deploy')
          end
        end

        it 'cancels the running build and shows retry button', :sidekiq_might_not_need_inline do
          find('#ci-badge-deploy .ci-action-icon-container').click

          page.within('#ci-badge-deploy') do
            expect(page).to have_css('.js-icon-retry')
          end
        end
      end

      context 'when pipeline has preparing builds' do
        before do
          visit_pipeline
        end

        it 'shows a preparing icon and a cancel action' do
          page.within('#ci-badge-prepare') do
            expect(page).to have_selector('[data-testid="status_preparing_borderless-icon"]')
            expect(page).to have_selector('.js-icon-cancel')
            expect(page).to have_content('prepare')
          end
        end

        it 'does not show the retry button' do
          find('#ci-badge-deploy .ci-action-icon-container').click

          page.within('#ci-badge-deploy') do
            expect(page).not_to have_css('.js-icon-retry')
          end
        end
      end

      context 'when pipeline has successful builds' do
        before do
          visit_pipeline
        end

        it 'shows the success icon and a retry action for the successful build' do
          page.within('#ci-badge-build') do
            expect(page).to have_selector('[data-testid="status_success_borderless-icon"]')
            expect(page).to have_content('build')
          end

          page.within('#ci-badge-build .ci-action-icon-container.js-icon-retry') do
            expect(page).to have_selector('svg')
          end
        end

        it 'is possible to retry the success job', :sidekiq_might_not_need_inline do
          find('#ci-badge-build .ci-action-icon-container').click
          wait_for_requests

          expect(page).not_to have_content('Retry job')
          within_testid('pipeline-header') do
            expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Running')
          end
        end
      end

      context 'when pipeline has a delayed job' do
        before do
          visit_pipeline
        end

        let(:project) { create(:project, :repository, group: group) }

        it 'shows the scheduled icon and an unschedule action for the delayed job' do
          page.within('#ci-badge-delayed-job') do
            expect(page).to have_selector('[data-testid="status_scheduled_borderless-icon"]')
            expect(page).to have_content('delayed-job')
          end

          page.within('#ci-badge-delayed-job .ci-action-icon-container.js-icon-time-out') do
            expect(page).to have_selector('svg')
          end
        end

        it 'unschedules the delayed job and shows play button as a manual job', :sidekiq_might_not_need_inline do
          find('#ci-badge-delayed-job .ci-action-icon-container').click

          page.within('#ci-badge-delayed-job') do
            expect(page).to have_css('.js-icon-play')
          end
        end
      end

      context 'when pipeline has failed builds' do
        before do
          visit_pipeline
        end

        it 'shows the failed icon and a retry action for the failed build' do
          page.within('#ci-badge-test') do
            expect(page).to have_selector('[data-testid="status_failed_borderless-icon"]')
            expect(page).to have_content('test')
          end

          page.within('#ci-badge-test .ci-action-icon-container.js-icon-retry') do
            expect(page).to have_selector('svg')
          end
        end

        it 'is possible to retry the failed build', :sidekiq_might_not_need_inline do
          find('#ci-badge-test .ci-action-icon-container').click
          wait_for_requests

          expect(page).not_to have_content('Retry job')
          within_testid('pipeline-header') do
            expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Running')
          end
        end

        it 'includes the failure reason' do
          page.within('#ci-badge-test') do
            # TODO Find way to locate this link with title
            build_link = find_by_testid('ci-job-item').find('a')
            expect(build_link['title']).to eq('Failed - (unknown failure)')
          end
        end
      end

      context 'when pipeline has manual jobs' do
        before do
          visit_pipeline
        end

        it 'shows the skipped icon and a play action for the manual build' do
          page.within('#ci-badge-manual-build') do
            expect(page).to have_selector('[data-testid="status_manual_borderless-icon"]')
            expect(page).to have_content('manual')
          end

          page.within('#ci-badge-manual-build .ci-action-icon-container.js-icon-play') do
            expect(page).to have_selector('svg')
          end
        end

        it 'is possible to play the manual job', :sidekiq_might_not_need_inline do
          find('#ci-badge-manual-build .ci-action-icon-container').click
          wait_for_requests

          expect(page).not_to have_content('Run job')
          within_testid('pipeline-header') do
            expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Running')
          end
        end
      end

      context 'when pipeline has external job' do
        before do
          visit_pipeline
        end

        it 'shows the success icon and the generic comit status build' do
          expect(page).to have_selector('[data-testid="status_success_borderless-icon"]')
          expect(page).to have_content('jenkins')
          expect(page).to have_link('jenkins', href: 'http://gitlab.com/status')
        end
      end

      context 'when pipeline has a downstream pipeline' do
        let(:downstream_project) { create(:project, :repository, group: group) }
        let(:downstream_pipeline) do
          create(
            :ci_pipeline,
            status,
            user: user,
            project: downstream_project,
            ref: 'master',
            sha: downstream_project.commit.id,
            child_of: pipeline
          )
        end

        let!(:build) { create(:ci_build, status, pipeline: downstream_pipeline, user: user) }

        before do
          downstream_pipeline.project.add_developer(user)
        end

        context 'and user has permission' do
          before do
            visit_pipeline
          end

          context 'with a successful downstream' do
            let(:status) { :success }

            it 'does not show the cancel or retry action' do
              expect(page).to have_selector('[data-testid="status_success_borderless-icon"]')
              expect(page).not_to have_selector('button[aria-label="Retry downstream pipeline"]')
              expect(page).not_to have_selector('button[aria-label="Cancel downstream pipeline"]')
            end
          end

          context 'with a running downstream' do
            let(:status) { :running }

            it 'shows the cancel action' do
              expect(page).to have_selector('button[aria-label="Cancel downstream pipeline"]')
            end

            context 'when cancel button clicked', :sidekiq_inline do
              before do
                find('button[aria-label="Cancel downstream pipeline"]').click
              end

              it 'shows the pipeline as canceling with the retry action' do
                expect(page).to have_selector('[data-testid="status_canceled_borderless-icon"]')
                expect(page).to have_selector('button[aria-label="Retry downstream pipeline"]')
              end
            end
          end

          context 'with a failed downstream' do
            let(:status) { :failed }

            it 'indicates that pipeline can be retried' do
              expect(page).to have_selector('button[aria-label="Retry downstream pipeline"]')
            end

            context 'when retrying' do
              before do
                find('button[aria-label="Retry downstream pipeline"]').click
                wait_for_requests
              end

              it 'shows running pipeline with the cancel action' do
                expect(page).to have_selector('[data-testid="status_running_borderless-icon"]')
                expect(page).to have_selector('button[aria-label="Cancel downstream pipeline"]')
              end
            end
          end

          context 'with a canceled downstream' do
            let(:status) { :canceled }

            it 'indicates that pipeline can be retried' do
              expect(page).to have_selector('button[aria-label="Retry downstream pipeline"]')
            end

            context 'when retrying' do
              before do
                find('button[aria-label="Retry downstream pipeline"]').click
                wait_for_requests
              end

              it 'shows running pipeline with the cancel action' do
                expect(page).to have_selector('[data-testid="status_running_borderless-icon"]')
                expect(page).to have_selector('button[aria-label="Cancel downstream pipeline"]')
              end
            end
          end
        end

        context 'when user does not have permissions' do
          let(:status) { :failed }

          before do
            new_user = create(:user)
            project.add_role(new_user, :guest)
            downstream_project.add_role(new_user, :guest)
            sign_in(new_user)

            visit_pipeline
          end

          it 'does not show the retry button' do
            expect(page).to have_selector('[data-testid="status_failed_borderless-icon"]')
            expect(page).not_to have_selector('button[aria-label="Retry downstream pipeline"]')
          end
        end
      end
    end

    context 'when the pipeline has manual stage' do
      before do
        create(:ci_build, :manual, pipeline: pipeline, stage_idx: 10, stage: 'publish', name: 'CentOS')
        create(:ci_build, :manual, pipeline: pipeline, stage_idx: 10, stage: 'publish', name: 'Debian')
        create(:ci_build, :manual, pipeline: pipeline, stage_idx: 10, stage: 'publish', name: 'OpenSUDE')

        # force to update stages statuses
        Ci::ProcessPipelineService.new(pipeline).execute

        visit_pipeline
      end

      it 'displays play all button' do
        expect(page).to have_selector('.js-stage-action')
      end
    end

    context 'page tabs' do
      before do
        visit_pipeline
      end

      it 'shows Pipeline, Jobs, and Failed Jobs tabs with link' do
        expect(page).to have_link('Pipeline')
        expect(page).to have_link('Jobs')
        expect(page).to have_link('Failed Jobs')
      end

      it 'shows counter in Jobs tab' do
        expect(find_by_testid('builds-counter').text).to eq(pipeline.total_size.to_s)
      end

      context 'without permission to access builds' do
        let(:project) { create(:project, :public, :repository, public_builds: false) }
        let(:role) { :guest }

        it 'does not show the pipeline details page' do
          expect(page).to have_content('Page not found')
        end
      end
    end

    describe 'test tabs' do
      let(:pipeline) { create(:ci_pipeline, :with_test_reports, :with_report_results, project: project) }

      before do
        visit_pipeline
        wait_for_requests
      end

      context 'with test reports' do
        it 'shows badge counter in Tests tab' do
          expect(find_by_testid('tests-counter').text).to eq(pipeline.test_report_summary.total[:count].to_s)
        end

        it 'calls summary.json endpoint', :js do
          find('.gl-tab-nav-item', text: 'Tests').click

          expect(page).to have_content('Jobs')
          expect(page).to have_selector('[data-testid="tests-detail"]', visible: :all)
        end
      end

      context 'without test reports' do
        let(:pipeline) { create(:ci_pipeline, project: project) }

        it 'shows zero' do
          expect(find_by_testid('tests-counter', visible: :all).text).to eq("0")
        end
      end
    end

    context 'retrying jobs' do
      before do
        visit_pipeline
      end

      it { expect(page).not_to have_content('retried') }

      context 'when retrying' do
        before do
          find_by_testid('retry-pipeline').click
          wait_for_requests
        end

        it 'does not show a "Retry" button', :sidekiq_might_not_need_inline do
          expect(page).not_to have_content('Retry')
        end

        it 'shows running status in pipeline header', :sidekiq_might_not_need_inline do
          within_testid('pipeline-header') do
            expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Running')
          end
        end
      end
    end

    context 'canceling jobs' do
      before do
        visit_pipeline
        click_on 'Cancel pipeline'
      end

      it 'does not show a "Cancel pipeline" button', :sidekiq_inline do
        expect(page).not_to have_content('Cancel pipeline')
      end
    end

    context 'when user can not delete' do
      before do
        visit_pipeline
      end

      it { expect(page).not_to have_button('Delete') }
    end

    context 'when deleting' do
      before do
        group.add_owner(user)

        visit_pipeline

        click_button 'Delete'
        click_button 'Delete pipeline'
      end

      it 'redirects to pipeline overview page', :sidekiq_inline do
        expect(page).to have_content('The pipeline has been deleted')
        expect(page).to have_current_path(project_pipelines_path(project), ignore_query: true)
      end
    end

    context 'when pipeline ref does not exist in repository anymore' do
      let(:pipeline) do
        create(
          :ci_empty_pipeline,
          project: project,
          ref: 'non-existent',
          sha: project.commit.id,
          user: user
        )
      end

      before do
        visit_pipeline
      end

      it 'does not render link to the pipeline ref' do
        expect(page).not_to have_link(pipeline.ref)
        expect(page).to have_content(pipeline.ref)
      end

      it 'does not render render raw HTML to the pipeline ref' do
        within_testid 'pipeline-header' do
          expect(page).not_to have_content('<span class="ref-name"')
        end
      end
    end

    context 'when pipeline is detached merge request pipeline' do
      let(:source_project) { project }
      let(:target_project) { project }

      let(:merge_request) do
        create(
          :merge_request,
          :with_detached_merge_request_pipeline,
          source_project: source_project,
          target_project: target_project
        )
      end

      let(:pipeline) do
        merge_request.all_pipelines.last
      end

      it 'shows the pipeline information' do
        visit_pipeline

        within_testid 'pipeline-header' do
          expect(page).to have_content("#{pipeline.statuses.count} jobs")
          expect(page).to have_content("Related merge request !#{merge_request.iid} " \
                                       "to merge #{merge_request.source_branch}")
          expect(page).to have_link("!#{merge_request.iid}",
            href: project_merge_request_path(project, merge_request))
          expect(page).to have_link(merge_request.source_branch,
            href: project_commits_path(merge_request.source_project, merge_request.source_branch))
        end
      end

      context 'when source branch does not exist' do
        before do
          project.repository.rm_branch(user, merge_request.source_branch)
        end

        it 'does not link to the source branch commit path' do
          visit_pipeline

          within_testid 'pipeline-header' do
            expect(page).not_to have_link(merge_request.source_branch)
            expect(page).to have_content(merge_request.source_branch)
          end
        end
      end

      context 'when source project is a forked project' do
        let(:source_project) { fork_project(project, user, repository: true) }

        before do
          visit project_pipeline_path(source_project, pipeline)
        end

        it 'shows the pipeline information', :sidekiq_might_not_need_inline do
          within_testid 'pipeline-header' do
            expect(page).to have_content("#{pipeline.statuses.count} jobs")
            expect(page).to have_content("Related merge request !#{merge_request.iid} " \
                                         "to merge #{merge_request.source_branch}")
            expect(page).to have_link("!#{merge_request.iid}",
              href: project_merge_request_path(project, merge_request))
            expect(page).to have_link(merge_request.source_branch,
              href: project_commits_path(merge_request.source_project, merge_request.source_branch))
          end
        end
      end
    end

    context 'when pipeline is merge request pipeline' do
      let(:project) { create(:project, :repository, group: group) }
      let(:source_project) { project }
      let(:target_project) { project }

      let(:merge_request) do
        create(:merge_request,
          :with_merge_request_pipeline,
          source_project: source_project,
          target_project: target_project,
          merge_sha: project.commit.id)
      end

      let(:pipeline) do
        merge_request.all_pipelines.last
      end

      before do
        pipeline.update!(user: user)
      end

      it 'shows the pipeline information' do
        visit_pipeline

        within_testid 'pipeline-header' do
          expect(page).to have_content("#{pipeline.statuses.count} jobs")
          expect(page).to have_content("Related merge request !#{merge_request.iid} " \
                                       "to merge #{merge_request.source_branch} " \
                                       "into #{merge_request.target_branch}")
          expect(page).to have_link("!#{merge_request.iid}",
            href: project_merge_request_path(project, merge_request))
          expect(page).to have_link(merge_request.source_branch,
            href: project_commits_path(merge_request.source_project, merge_request.source_branch))
          expect(page).to have_link(merge_request.target_branch,
            href: project_commits_path(merge_request.target_project, merge_request.target_branch))
        end
      end

      context 'when target branch does not exist' do
        before do
          project.repository.rm_branch(user, merge_request.target_branch)
        end

        it 'does not link to the target branch commit path' do
          visit_pipeline

          within_testid 'pipeline-header' do
            expect(page).not_to have_link(merge_request.target_branch)
            expect(page).to have_content(merge_request.target_branch)
          end
        end
      end

      context 'when source project is a forked project' do
        let(:source_project) { fork_project(project, user, repository: true) }

        before do
          visit project_pipeline_path(source_project, pipeline)
        end

        it 'shows the pipeline information', :sidekiq_might_not_need_inline do
          within_testid 'pipeline-header' do
            expect(page).to have_content("#{pipeline.statuses.count} jobs")
            expect(page).to have_content("Related merge request !#{merge_request.iid} " \
                                       "to merge #{merge_request.source_branch} " \
                                       "into #{merge_request.target_branch}")
            expect(page).to have_link("!#{merge_request.iid}",
              href: project_merge_request_path(project, merge_request))
            expect(page).to have_link(merge_request.source_branch,
              href: project_commits_path(merge_request.source_project, merge_request.source_branch))
            expect(page).to have_link(merge_request.target_branch,
              href: project_commits_path(merge_request.target_project, merge_request.target_branch))
          end
        end
      end
    end
  end

  context 'when user does not have access to read jobs' do
    before do
      project.update!(public_builds: false)
    end

    describe 'GET /:project/-/pipelines/:id' do
      include_context 'pipeline builds'

      let_it_be(:project) { create(:project, :repository) }

      let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id, user: user) }

      before do
        visit project_pipeline_path(project, pipeline)
      end

      it 'shows the pipeline graph' do
        expect(page).to have_selector('.js-pipeline-graph')
        expect(page).to have_content('build')
        expect(page).to have_content('test')
        expect(page).to have_content('deploy')
        expect(page).to have_content('Retry')
        expect(page).to have_content('Cancel pipeline')
      end

      it 'does link to job' do
        expect(page).to have_selector('[data-testid="ci-job-item"]')
      end
    end
  end

  context 'when a bridge job exists' do
    include_context 'pipeline builds'

    let(:project) { create(:project, :repository) }
    let(:downstream) { create(:project, :repository) }

    let(:pipeline) do
      create(
        :ci_pipeline,
        project: project,
        ref: 'master',
        sha: project.commit.id,
        user: user
      )
    end

    let!(:bridge) do
      create(
        :ci_bridge,
        pipeline: pipeline,
        name: 'cross-build',
        user: user,
        downstream: downstream
      )
    end

    describe 'GET /:project/-/pipelines/:id' do
      before do
        visit project_pipeline_path(project, pipeline)
      end

      it 'shows the pipeline with a bridge job' do
        expect(page).to have_selector('.js-pipeline-graph')
        expect(page).to have_content('cross-build')
      end

      context 'when a scheduled pipeline is created by a blocked user' do
        let(:project)  { create(:project, :repository) }

        let(:schedule) do
          create(:ci_pipeline_schedule,
            project: project,
            owner: project.first_owner,
            description: 'blocked user schedule'
          ).tap do |schedule|
            schedule.update_column(:next_run_at, 1.minute.ago)
          end
        end

        before do
          schedule.owner.block!
          PipelineScheduleWorker.new.perform
        end

        it 'displays the PipelineSchedule in an inactive state' do
          visit project_pipeline_schedules_path(project)
          page.click_link('Inactive')

          expect(page).to have_selector('[data-testid="pipeline-schedule-description"]', text: 'blocked user schedule')
        end

        it 'does not create a new Pipeline', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/408215' do
          visit project_pipelines_path(project)

          expect(page).not_to have_selector('.ci-table')
          expect(schedule.last_pipeline).to be_nil
        end
      end
    end

    describe 'GET /:project/-/pipelines/:id/builds' do
      before do
        visit builds_project_pipeline_path(project, pipeline)
      end

      it 'shows a bridge job on a list' do
        expect(page).to have_content('cross-build')
        expect(page).to have_content(bridge.id)
      end
    end
  end

  context 'when build requires resource', :sidekiq_inline do
    let_it_be(:project) { create(:project, :repository) }

    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:resource_group) { create(:ci_resource_group, project: project) }

    let!(:test_job) do
      create(:ci_build, :pending, stage: 'test', name: 'test', stage_idx: 1, pipeline: pipeline, project: project)
    end

    let!(:deploy_job) do
      create(
        :ci_build,
        :created,
        stage: 'deploy',
        name: 'deploy',
        stage_idx: 2,
        pipeline: pipeline,
        project: project,
        resource_group: resource_group
      )
    end

    describe 'GET /:project/-/pipelines/:id' do
      subject { visit project_pipeline_path(project, pipeline) }

      it 'shows deploy job as created' do
        subject

        within_testid('pipeline-header') do
          expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Pending')
        end

        within('.js-pipeline-graph') do
          within(all('[data-testid="stage-column"]')[0]) do
            expect(page).to have_content('test')
            expect(page).to have_css('[data-testid="status_pending_borderless-icon"]')
          end

          within(all('[data-testid="stage-column"]')[1]) do
            expect(page).to have_content('deploy')
            expect(page).to have_css('[data-testid="status_created_borderless-icon"]')
          end
        end
      end

      context 'when test job succeeded' do
        before do
          test_job.success!
        end

        it 'shows deploy job as pending' do
          subject

          within_testid('pipeline-header') do
            expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Running')
          end

          within('.js-pipeline-graph') do
            within(all('[data-testid="stage-column"]')[0]) do
              expect(page).to have_content('test')
              expect(page).to have_css('[data-testid="status_success_borderless-icon"]')
            end

            within(all('[data-testid="stage-column"]')[1]) do
              expect(page).to have_content('deploy')
              expect(page).to have_css('[data-testid="status_pending_borderless-icon"]')
            end
          end
        end
      end

      context 'when test job succeeded but there are no available resources' do
        let(:another_job) { create(:ci_build, :running, project: project, resource_group: resource_group) }

        before do
          resource_group.assign_resource_to(another_job)
          test_job.success!
        end

        it 'shows deploy job as waiting for resource' do
          subject

          within_testid('pipeline-header') do
            expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Waiting')
          end

          within('.js-pipeline-graph') do
            within(all('[data-testid="stage-column"]')[1]) do
              expect(page).to have_content('deploy')
              expect(page).to have_css('[data-testid="status_pending_borderless-icon"]')
            end
          end
        end

        context 'when resource is released from another job' do
          before do
            another_job.success!
          end

          it 'shows deploy job as pending' do
            subject

            within_testid('pipeline-header') do
              expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Running')
            end

            within('.js-pipeline-graph') do
              within(all('[data-testid="stage-column"]')[1]) do
                expect(page).to have_content('deploy')
                expect(page).to have_css('[data-testid="status_pending_borderless-icon"]')
              end
            end
          end
        end

        context 'when deploy job is a bridge to trigger a downstream pipeline' do
          let!(:deploy_job) do
            create(:ci_bridge, :created,
              stage: 'deploy',
              name: 'deploy',
              stage_idx: 2,
              pipeline: pipeline,
              project: project,
              resource_group: resource_group
            )
          end

          it 'shows deploy job as waiting for resource' do
            subject

            within_testid('pipeline-header') do
              expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Waiting')
            end

            within('.js-pipeline-graph') do
              within(all('[data-testid="stage-column"]')[1]) do
                expect(page).to have_content('deploy')
                expect(page).to have_css('[data-testid="status_pending_borderless-icon"]')
              end
            end
          end
        end
      end
    end
  end

  describe 'GET /:project/-/pipelines/:id/builds' do
    include_context 'pipeline builds'

    let_it_be(:project) { create(:project, :repository) }

    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

    before do
      visit builds_project_pipeline_path(project, pipeline)
    end

    it 'shows a list of jobs' do
      expect(page).to have_content('Test')
      expect(page).to have_content(build_passed.id)
      expect(page).to have_content('Deploy')
      expect(page).to have_content(build_failed.id)
      expect(page).to have_content(build_running.id)
      expect(page).to have_content(build_external.id)
      expect(page).to have_content('Retry')
      expect(page).to have_content('Cancel pipeline')
      expect(page).to have_button('Run')
    end

    context 'page tabs' do
      it 'shows Pipeline and Jobs tabs with link' do
        expect(page).to have_link('Pipeline')
        expect(page).to have_link('Jobs')
      end

      it 'shows counter in Jobs tab' do
        expect(find_by_testid('builds-counter').text).to eq(pipeline.total_size.to_s)
      end
    end

    context 'retrying jobs' do
      it { expect(page).not_to have_content('retried') }

      context 'when retrying' do
        before do
          find_by_testid('retry', match: :first).click
        end

        it 'does not show a "Retry" button', :sidekiq_might_not_need_inline do
          expect(page).not_to have_content('Retry')
        end
      end
    end

    context 'canceling jobs' do
      it { expect(page).not_to have_selector('.ci-canceled') }

      context 'when canceling' do
        before do
          click_on 'Cancel pipeline'
        end

        it 'does not show a "Cancel pipeline" button', :sidekiq_might_not_need_inline do
          expect(page).not_to have_content('Cancel pipeline')
        end
      end
    end

    context 'playing manual job' do
      before do
        within_testid 'jobs-tab-table' do
          click_button('Run')

          wait_for_requests
        end
      end

      it { expect(build_manual.reload).to be_pending }
    end

    context 'when user unschedules a delayed job' do
      before do
        within_testid 'jobs-tab-table' do
          click_button('Unschedule')
        end
      end

      it 'unschedules the delayed job and shows play button as a manual job' do
        expect(page).to have_button('Run')
        expect(page).not_to have_button('Unschedule')
      end
    end
  end

  describe 'GET /:project/-/pipelines/:id/failures' do
    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: '1234') }
    let(:pipeline_failures_page) { failures_project_pipeline_path(project, pipeline) }
    let!(:failed_build) { create(:ci_build, :failed, pipeline: pipeline) }

    subject { visit pipeline_failures_page }

    context 'with failed build' do
      before do
        failed_build.trace.set('4 examples, 1 failure')
      end

      it 'lists failed builds' do
        subject

        expect(page).to have_content(failed_build.name)
        expect(page).to have_content(failed_build.stage_name)
      end

      it 'shows build failure logs' do
        subject

        expect(page).to have_content('4 examples, 1 failure')
      end

      it 'shows the failure reason' do
        subject

        expect(page).to have_content('There is an unknown failure, please try again')
      end

      context 'when user does not have permission to retry build' do
        it 'shows retry button for failed build' do
          subject

          within_testid('tab-failures', match: :first) do
            expect(page).not_to have_button('Retry')
          end
        end
      end

      context 'when user does have permission to retry build' do
        before do
          create(:protected_branch, :developers_can_merge, name: pipeline.ref, project: project)
        end

        it 'shows retry button for failed build' do
          subject

          within_testid('tab-failures', match: :first) do
            expect(page).to have_button('Retry')
          end
        end
      end
    end

    context 'when missing build logs' do
      it 'lists failed builds' do
        subject

        expect(page).to have_content(failed_build.name)
        expect(page).to have_content(failed_build.stage_name)
      end

      it 'does not show log' do
        subject

        expect(page).to have_content('No job log')
      end
    end

    context 'without permission to access builds' do
      let(:role) { :guest }

      before do
        project.update!(public_builds: false)
      end

      context 'when accessing failed jobs page' do
        it 'renders a 404 page' do
          requests = inspect_requests { subject }

          expect(page).to have_title('Not Found')
          expect(requests.first.status_code).to eq(404)
        end
      end
    end

    context 'without failures' do
      before do
        failed_build.update!(status: :success)
      end

      it 'does not show the failure tab' do
        subject

        expect(page).not_to have_content('Failed Jobs')
      end

      it 'displays the pipeline graph' do
        subject

        expect(page).to have_current_path(pipeline_path(pipeline))
        expect(page).to have_selector('.js-pipeline-graph')
      end
    end
  end

  describe 'GET /:project/-/pipelines/latest' do
    let_it_be(:project) { create(:project, :repository) }

    let!(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

    before do
      visit latest_project_pipelines_path(project)
    end

    it 'displays the pipeline graph with correct URL' do
      expect(page).to have_current_path("#{pipeline_path(pipeline)}/")
      expect(page).to have_selector('.js-pipeline-graph')
    end
  end

  context 'when user sees pipeline flags in a pipeline detail page' do
    let_it_be(:project) { create(:project, :repository) }

    context 'when pipeline is latest' do
      include_context 'pipeline builds'

      let(:pipeline) do
        create(
          :ci_pipeline,
          project: project,
          ref: 'master',
          sha: project.commit.id,
          user: user
        )
      end

      before do
        visit project_pipeline_path(project, pipeline)
      end

      it 'contains badge that indicates it is the latest build' do
        within_testid('pipeline-header') do
          expect(page).to have_content 'latest'
        end
      end
    end

    context 'when pipeline has configuration errors' do
      let(:pipeline) do
        create(
          :ci_pipeline,
          :invalid_config_error,
          project: project,
          ref: 'master',
          sha: project.commit.id,
          user: user
        )
      end

      before do
        pipeline.add_error_message('invalid YAML')
        pipeline.save!
        visit project_pipeline_path(project, pipeline)
      end

      it 'contains badge that indicates errors' do
        within_testid('pipeline-header') do
          expect(page).to have_content 'yaml invalid'
        end
      end

      it 'contains badge with tooltip which contains error' do
        expect(pipeline.error_messages).not_to be_empty

        within_testid('pipeline-header') do
          expect(page).to have_selector(
            %(span[title="#{pipeline.error_messages.first.content}"]))
        end
      end

      it 'contains badge that indicates failure reason' do
        expect(page).to have_content 'error'
      end

      it 'contains badge with tooltip which contains failure reason' do
        expect(pipeline.failure_reason?).to eq true

        within_testid('pipeline-header') do
          expect(page).to have_selector(
            %(span[title="#{pipeline.present.failure_reason}"]))
        end
      end
    end

    context 'when pipeline is stuck' do
      let(:pipeline) do
        create(:ci_pipeline, project: project, status: :created, user: user)
      end

      before do
        create(:ci_build, :pending, pipeline: pipeline)
        visit project_pipeline_path(project, pipeline)
      end

      it 'contains badge that indicates being stuck' do
        within_testid('pipeline-header') do
          expect(page).to have_content 'stuck'
        end
      end
    end

    context 'when pipeline uses auto devops' do
      include_context 'pipeline builds'

      let(:project) { create(:project, :repository, auto_devops_attributes: { enabled: true }) }
      let(:pipeline) do
        create(
          :ci_pipeline,
          :auto_devops_source,
          project: project,
          ref: 'master',
          sha: project.commit.id,
          user: user
        )
      end

      before do
        visit project_pipeline_path(project, pipeline)
      end

      it 'contains badge that indicates using auto devops' do
        within_testid('pipeline-header') do
          expect(page).to have_content 'Auto DevOps'
        end
      end
    end

    context 'when pipeline runs in a merge request context' do
      include_context 'pipeline builds'

      let(:pipeline) do
        create(
          :ci_pipeline,
          source: :merge_request_event,
          project: merge_request.source_project,
          ref: 'feature',
          sha: merge_request.diff_head_sha,
          user: user,
          merge_request: merge_request
        )
      end

      let(:merge_request) do
        create(
          :merge_request,
          source_project: project,
          source_branch: 'feature',
          target_project: project,
          target_branch: 'master'
        )
      end

      before do
        visit project_pipeline_path(project, pipeline)
      end

      it 'contains badge that indicates detached merge request pipeline' do
        within_testid('pipeline-header') do
          expect(page).to have_content 'merge request'
        end
      end
    end
  end
end
