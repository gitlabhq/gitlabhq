# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipelines', :js, feature_category: :continuous_integration do
  include ListboxHelpers
  include ProjectForksHelper
  include Spec::Support::Helpers::ModalHelpers

  let(:project) { create(:project) }
  let(:expected_detached_mr_tag) { 'merge request' }

  context 'when user is logged in' do
    let(:user) { create(:user) }

    before do
      sign_in(user)

      project.add_developer(user)
      project.update!(auto_devops_attributes: { enabled: false })
    end

    describe 'GET /:project/-/pipelines' do
      let(:project) { create(:project, :repository) }

      let!(:pipeline) do
        create(
          :ci_empty_pipeline,
          project: project,
          ref: 'master',
          status: 'running',
          sha: project.commit.id
        )
      end

      context 'scope' do
        before do
          create(:ci_empty_pipeline, status: 'pending', project: project, sha: project.commit.id, ref: 'master')
          create(:ci_empty_pipeline, status: 'running', project: project, sha: project.commit.id, ref: 'master')
          create(:ci_empty_pipeline, status: 'created', project: project, sha: project.commit.id, ref: 'master')
          create(:ci_empty_pipeline, status: 'success', project: project, sha: project.commit.id, ref: 'master')
        end

        [:all, :running, :pending, :finished, :branches].each do |scope|
          context "when displaying #{scope}" do
            before do
              visit_project_pipelines(scope: scope)
            end

            it 'contains pipeline commit short SHA' do
              expect(page).to have_content(pipeline.short_sha)
            end

            it 'contains branch name' do
              expect(page).to have_content(pipeline.ref)
            end
          end
        end
      end

      context 'header tabs' do
        before do
          visit project_pipelines_path(project)
          wait_for_requests
        end

        it 'shows a tab for All pipelines and count' do
          expect(page.find('.js-pipelines-tab-all').text).to include('All')
          expect(page.find('.js-pipelines-tab-all .badge').text).to include('1')
        end

        it 'shows a tab for Finished pipelines and count' do
          expect(page.find('.js-pipelines-tab-finished').text).to include('Finished')
        end

        it 'shows a tab for Branches' do
          expect(page.find('.js-pipelines-tab-branches').text).to include('Branches')
        end

        it 'shows a tab for Tags' do
          expect(page.find('.js-pipelines-tab-tags').text).to include('Tags')
        end

        it 'updates content when tab is clicked' do
          page.find('.js-pipelines-tab-finished').click
          wait_for_requests
          expect(page).to have_content('There are currently no finished pipelines.')
        end
      end

      context 'navigation links' do
        before do
          visit project_pipelines_path(project)
          wait_for_requests
        end

        it 'renders "New pipeline" link' do
          expect(page).to have_link('New pipeline')
        end
      end

      context 'when pipeline is cancelable' do
        let!(:job) do
          create(:ci_build, pipeline: pipeline, stage: 'test')
        end

        before do
          stub_const("::Projects::PipelinesController::POLLING_INTERVAL", 1)
          job.run
          visit_project_pipelines
        end

        context 'when canceling support is disabled' do
          it 'indicates that pipeline can be canceled' do
            expect(page).to have_selector('.js-pipelines-cancel-button')
            expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Running')
          end

          context 'when canceling' do
            it 'indicates that pipelines was canceled', :sidekiq_inline do
              find('.js-pipelines-cancel-button').click
              click_button 'Stop pipeline'

              wait_for_requests

              expect(page).not_to have_selector('.js-pipelines-cancel-button')
              expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Canceled')
            end

            it 'targets the pipeline the cancel action was invoked on' do
              allow_next_instance_of(Gitlab::EtagCaching::Store) do |instance|
                allow(instance).to receive(:get).and_return(nil)
              end

              expect(page).to have_selector('[data-testid="pipeline-table-row"]', count: 1)

              find('.js-pipelines-cancel-button').click

              within_testid 'pipeline-stop-modal' do
                expect(page).to have_content("Stop pipeline ##{pipeline.id}?")
              end

              create(
                :ci_pipeline,
                :running,
                project: project,
                source: Enums::Ci::Pipeline.sources[:push],
                ref: 'master',
                sha: 'sha'
              )

              expect(page).to have_selector('[data-testid="pipeline-table-row"]', count: 2)

              within_testid 'pipeline-stop-modal' do
                expect(page).to have_content("Stop pipeline ##{pipeline.id}?")
              end
            end
          end
        end

        context 'when canceling support is enabled' do
          include_context 'when canceling support'

          it 'indicates that pipeline can be canceled' do
            expect(page).to have_selector('.js-pipelines-cancel-button')
            expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Running')
          end

          context 'when canceling' do
            before do
              find('.js-pipelines-cancel-button').click
              click_button 'Stop pipeline'
              wait_for_requests
            end

            it 'indicates that pipeline is canceling', :sidekiq_inline do
              expect(page).not_to have_selector('.js-pipelines-cancel-button')
              expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Canceling')
            end
          end
        end
      end

      context 'when pipeline is retryable', :sidekiq_might_not_need_inline do
        let!(:build) do
          create(:ci_build, pipeline: pipeline, stage: 'test')
        end

        before do
          build.drop
          visit_project_pipelines
        end

        it 'indicates that pipeline can be retried' do
          expect(page).to have_selector('.js-pipelines-retry-button')
          expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Failed')
        end

        context 'when retrying' do
          before do
            find('.js-pipelines-retry-button').click
            wait_for_requests
          end

          it 'shows running pipeline that is not retryable' do
            expect(page).not_to have_selector('.js-pipelines-retry-button')
            expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Running')
          end
        end
      end

      context 'when pipeline is detached merge request pipeline' do
        let(:merge_request) do
          create(
            :merge_request,
            :with_detached_merge_request_pipeline,
            source_project: source_project,
            target_project: target_project
          )
        end

        let!(:pipeline) { merge_request.all_pipelines.first }
        let(:source_project) { project }
        let(:target_project) { project }

        before do
          visit project_pipelines_path(source_project)
        end

        shared_examples_for 'detached merge request pipeline' do
          it 'shows pipeline information without pipeline ref', :sidekiq_might_not_need_inline do
            within '.pipeline-tags' do
              expect(page).to have_content(expected_detached_mr_tag)

              expect(page).to have_link(merge_request.iid.to_s, href: project_merge_request_path(project, merge_request))

              expect(page).not_to have_link(pipeline.ref)
            end
          end
        end

        it_behaves_like 'detached merge request pipeline'

        context 'when source project is a forked project' do
          let(:source_project) { fork_project(project, user, repository: true) }

          it_behaves_like 'detached merge request pipeline'
        end
      end

      context 'when pipeline is merge request pipeline' do
        let(:merge_request) do
          create(
            :merge_request,
            :with_merge_request_pipeline,
            source_project: source_project,
            target_project: target_project,
            merge_sha: target_project.commit.sha
          )
        end

        let!(:pipeline) { merge_request.all_pipelines.first }
        let(:source_project) { project }
        let(:target_project) { project }

        before do
          visit project_pipelines_path(source_project)
        end

        shared_examples_for 'Correct merge request pipeline information' do
          it 'does not show detached tag for the pipeline, and shows the link of the merge request, and does not show the ref of the pipeline', :sidekiq_might_not_need_inline do
            within '.pipeline-tags' do
              expect(page).not_to have_content(expected_detached_mr_tag)

              expect(page).to have_link(merge_request.iid.to_s, href: project_merge_request_path(project, merge_request))

              expect(page).not_to have_link(pipeline.ref)
            end
          end
        end

        it_behaves_like 'Correct merge request pipeline information'

        context 'when source project is a forked project' do
          let(:source_project) { fork_project(project, user, repository: true) }

          it_behaves_like 'Correct merge request pipeline information'
        end
      end

      context 'when pipeline has configuration errors' do
        let(:pipeline) do
          create(:ci_pipeline, :invalid, project: project)
        end

        before do
          visit_project_pipelines
        end

        it 'contains badge that indicates errors' do
          expect(page).to have_content 'yaml invalid'
        end

        it 'contains badge with tooltip which contains error' do
          expect(pipeline).to have_yaml_errors
          expect(page).to have_selector(
            %(span[title="#{pipeline.yaml_errors}"]))
        end

        it 'contains badge that indicates failure reason' do
          expect(page).to have_content 'error'
        end

        it 'contains badge with tooltip which contains failure reason' do
          expect(pipeline.failure_reason?).to eq true
          expect(page).to have_selector(
            %(span[title="#{pipeline.present.failure_reason}"]))
        end
      end

      context 'with manual actions', :js do
        let!(:manual) do
          create(:ci_build, :manual,
            pipeline: pipeline,
            name: 'manual build',
            stage: 'test')
        end

        before do
          visit_project_pipelines
        end

        it 'has a dropdown with play button' do
          expect(page).to have_selector('[data-testid="pipelines-manual-actions-dropdown"] [data-testid="play-icon"]')
        end

        it 'has link to the manual action' do
          find_by_testid('pipelines-manual-actions-dropdown').click

          wait_for_requests

          expect(page).to have_button('manual build')
        end

        context 'when manual action was played' do
          before do
            find_by_testid('pipelines-manual-actions-dropdown').click

            wait_for_requests

            click_button('manual build')

            wait_for_all_requests
          end

          it 'enqueues manual action job' do
            expect(manual.reload).to be_pending
          end
        end
      end

      context 'when there is a delayed job' do
        let!(:delayed_job) do
          create(:ci_build, :scheduled,
            pipeline: pipeline,
            name: 'delayed job 1',
            stage: 'test',
            scheduled_at: 2.hours.since + 2.minutes)
        end

        before do
          visit_project_pipelines
        end

        it 'has a dropdown for actionable jobs' do
          expect(page).to have_selector('[data-testid="pipelines-manual-actions-dropdown"] [data-testid="play-icon"]')
        end

        it "has link to the delayed job's action", :js do
          find_by_testid('pipelines-manual-actions-dropdown').click

          wait_for_requests

          expect(page).to have_button('delayed job 1')

          time_diff = [0, delayed_job.scheduled_at - Time.zone.now].max
          expect(page).to have_content(Time.at(time_diff).utc.strftime("%H:%M"))
        end

        context 'when delayed job is expired already' do
          let!(:delayed_job) do
            create(:ci_build, :expired_scheduled,
              pipeline: pipeline,
              name: 'delayed job 1',
              stage: 'test')
          end

          it "shows 00:00:00 as the remaining time", :js do
            find_by_testid('pipelines-manual-actions-dropdown').click

            wait_for_requests

            expect(page).to have_content("00:00:00")
          end
        end

        context 'when user played a delayed job immediately' do
          let(:manual_action_selector) { '[data-testid="pipelines-manual-actions-dropdown"] button' }
          let(:manual_action_dropdown) { '[data-testid="pipelines-manual-actions-dropdown"]' }

          before do
            find(manual_action_selector).click
            accept_gl_confirm do
              click_button 'delayed job 1'
            end

            # Click on the manual action dropdown and check if a request has been made
            find(manual_action_selector).click
            within(manual_action_dropdown) { find('.gl-spinner') }
            within(manual_action_dropdown) { find_by_testid('play-icon') }

            wait_for_requests
          end

          it 'enqueues the delayed job', :js do
            expect(delayed_job.reload).to be_pending
          end
        end
      end

      context 'for generic statuses' do
        context 'when preparing' do
          let!(:pipeline) do
            create(:ci_empty_pipeline,
              status: 'preparing', project: project)
          end

          let!(:status) do
            create(:generic_commit_status,
              :preparing, pipeline: pipeline)
          end

          before do
            visit_project_pipelines
          end

          it 'is cancelable' do
            expect(page).to have_selector('.js-pipelines-cancel-button')
          end

          it 'shows the pipeline as preparing' do
            expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Preparing')
          end
        end

        context 'when running' do
          let!(:running) do
            create(:generic_commit_status,
              status: 'running',
              pipeline: pipeline,
              stage: 'test')
          end

          before do
            visit_project_pipelines
          end

          it 'is cancelable' do
            expect(page).to have_selector('.js-pipelines-cancel-button')
          end

          it 'has pipeline running' do
            expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Running')
          end

          context 'when canceling' do
            before do
              find('.js-pipelines-cancel-button').click
              click_button 'Stop pipeline'
            end

            it 'indicates that pipeline was canceled', :sidekiq_might_not_need_inline do
              expect(page).not_to have_selector('.js-pipelines-cancel-button')
              expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Canceled')
            end
          end
        end

        context 'when failed' do
          let!(:status) do
            create(:generic_commit_status, :pending,
              pipeline: pipeline,
              stage: 'test')
          end

          before do
            status.drop
            visit_project_pipelines
          end

          it 'is not retryable' do
            expect(page).not_to have_selector('.js-pipelines-retry-button')
          end

          it 'has failed pipeline', :sidekiq_might_not_need_inline do
            expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Failed')
          end
        end
      end

      context 'downloadable pipelines' do
        context 'with artifacts' do
          let!(:with_artifacts) do
            build = create(:ci_build, :success,
              pipeline: pipeline,
              name: 'rspec tests',
              stage: 'test')

            create(:ci_job_artifact, :codequality, job: build)
          end

          before do
            visit_project_pipelines
          end

          it 'has artifacts dropdown' do
            expect(page).to have_selector('[data-testid="pipeline-multi-actions-dropdown"]')
          end
        end

        context 'with artifacts expired' do
          let!(:with_artifacts_expired) do
            create(:ci_build, :expired, :success,
              pipeline: pipeline,
              name: 'rspec',
              stage: 'test')
          end

          before do
            visit_project_pipelines
          end

          it { expect(page).not_to have_selector('[data-testid="artifact-item"]') }
        end

        context 'without artifacts' do
          let!(:without_artifacts) do
            create(:ci_build, :success,
              pipeline: pipeline,
              name: 'rspec',
              stage: 'test')
          end

          before do
            visit_project_pipelines
          end

          it { expect(page).not_to have_selector('[data-testid="artifact-item"]') }
        end

        context 'with trace artifact' do
          before do
            create(:ci_build, :success, :trace_artifact, pipeline: pipeline)

            visit_project_pipelines
          end

          it 'does not show trace artifact as artifacts' do
            expect(page).not_to have_selector('[data-testid="artifact-item"]')
          end
        end
      end

      context 'mini pipeline graph' do
        let!(:build) do
          create(:ci_build, :pending, pipeline: pipeline, stage: 'build', name: 'build')
        end

        dropdown_selector = '[data-testid="pipeline-mini-graph-dropdown"]'

        before do
          visit_project_pipelines
        end

        it 'renders a mini pipeline graph' do
          expect(page).to have_selector('[data-testid="pipeline-mini-graph"]')
          expect(page).to have_selector(dropdown_selector)
        end

        context 'when clicking a stage badge', :js do
          it 'opens a dropdown' do
            find_by_testid('pipeline-mini-graph-dropdown-toggle').click

            wait_for_requests

            expect(page).to have_link build.name
          end

          it 'is possible to cancel pending build' do
            find_by_testid('pipeline-mini-graph-dropdown-toggle').click

            wait_for_requests

            find_by_testid('ci-action-button').click
            wait_for_requests

            expect(build.reload).to be_canceled
          end

          context 'manual job', :js do
            let!(:build) do
              create(:ci_build, :manual, pipeline: pipeline, stage: 'build', name: 'manual-build')
            end

            it 'is possible to play manual build' do
              find_by_testid('pipeline-mini-graph-dropdown-toggle').click

              wait_for_requests

              within first('[data-testid="ci-job-item"]') do
                expect(find_by_testid('play-icon')).to be_visible
              end

              find_by_testid('ci-action-button').click
              wait_for_requests

              element = find_by_testid('pipeline-mini-graph-dropdown-toggle')
              expect(element['aria-expanded']).to eq "true"
              expect(element).to be_visible
            end
          end
        end

        context 'for a failed pipeline', :js do
          let!(:build) do
            create(:ci_build, :failed, pipeline: pipeline, stage: 'build', name: 'build')
          end

          it 'displays the failure reason' do
            find_by_testid('pipeline-mini-graph-dropdown-toggle').click

            wait_for_requests

            within_testid('pipeline-mini-graph-dropdown') do
              build_element = page.find('.ci-job-component [data-testid="job-name"]')
              expect(build_element['title']).to eq('Failed - (unknown failure)')
            end
          end
        end
      end

      context 'with pagination' do
        before do
          allow(Ci::Pipeline).to receive(:default_per_page).and_return(1)
          create(:ci_empty_pipeline, project: project)
        end

        it 'renders pagination' do
          visit project_pipelines_path(project)
          wait_for_requests

          expect(page).to have_selector('.gl-pagination')
        end

        it 'renders second page of pipelines' do
          visit project_pipelines_path(project, page: '2')
          wait_for_requests

          expect(page).to have_selector('[data-testid="gl-pagination-li"]', count: 4)
        end

        it 'shows updated content' do
          visit project_pipelines_path(project)
          wait_for_requests

          find_by_testid('gl-pagination-next').click

          expect(page).to have_selector('[data-testid="gl-pagination-li"]', count: 4)
        end
      end

      context 'with pipeline key selection' do
        before do
          visit project_pipelines_path(project)
          wait_for_requests
        end

        it 'changes the Pipeline ID column link to Pipeline IID and persists', :aggregate_failures do
          expect(page).to have_link(text: "##{pipeline.id}")

          select_from_listbox('Show Pipeline IID', from: 'Show Pipeline ID')

          expect(page).to have_link(text: "##{pipeline.iid}")

          visit project_pipelines_path(project)
          wait_for_requests

          expect(page).to have_link(text: "##{pipeline.iid}")
        end
      end
    end

    describe 'GET /:project/-/pipelines/show' do
      let(:project) { create(:project, :repository) }

      let(:pipeline) do
        create(
          :ci_empty_pipeline,
          project: project,
          sha: project.commit.id,
          user: user
        )
      end

      let(:external_stage) { create(:ci_stage, name: 'external', pipeline: pipeline) }

      before do
        create_build('build', 0, 'build', :success)
        create_build('test', 1, 'rspec 0:2', :pending)
        create_build('test', 1, 'rspec 1:2', :running)
        create_build('test', 1, 'spinach 0:2', :created)
        create_build('test', 1, 'spinach 1:2', :created)
        create_build('test', 1, 'audit', :created)
        create_build('deploy', 2, 'production', :created)

        create(:generic_commit_status, pipeline: pipeline, ci_stage: external_stage, name: 'jenkins', ref: 'master')

        visit project_pipeline_path(project, pipeline)
        wait_for_requests
      end

      it 'shows a graph with grouped stages' do
        expect(page).to have_css('.js-pipeline-graph')

        # header
        expect(page).to have_text("##{pipeline.id}")
        expect(page).to have_link(pipeline.user.name, href: /#{user_path(pipeline.user)}$/)

        # stages
        expect(page).to have_text('build')
        expect(page).to have_text('test')
        expect(page).to have_text('deploy')
        expect(page).to have_text('external')

        # builds
        expect(page).to have_text('rspec')
        expect(page).to have_text('spinach')
        expect(page).to have_text('rspec')
        expect(page).to have_text('production')
        expect(page).to have_text('jenkins')
      end

      def create_build(stage, stage_idx, name, status)
        create(:ci_build, pipeline: pipeline, stage: stage, stage_idx: stage_idx, name: name, status: status)
      end
    end

    describe 'POST /:project/-/pipelines' do
      let(:project) { create(:project, :repository) }

      before do
        visit new_project_pipeline_path(project)
      end

      context 'for valid commit', :js do
        before do
          click_button project.default_branch
          wait_for_requests

          find('.gl-new-dropdown-item', text: 'spooky-stuff').click
          wait_for_requests
        end

        context 'with gitlab-ci.yml', :js do
          before do
            stub_ci_pipeline_to_return_yaml_file
          end

          subject(:run_pipeline) do
            find_by_testid('run-pipeline-button', text: 'New pipeline').click

            wait_for_requests
          end

          it 'creates a new pipeline' do
            expect { run_pipeline }.to change { Ci::Pipeline.count }.by(1)

            expect(Ci::Pipeline.last).to be_web
          end

          context 'when variables are specified' do
            before do
              project.update!(ci_pipeline_variables_minimum_override_role: :developer)
            end

            it 'creates a new pipeline with variables' do
              within_testid('ci-variable-row-container') do
                find_by_testid('pipeline-form-ci-variable-key-field').set('key_name')
                find_by_testid('pipeline-form-ci-variable-value-field').set('value')
              end

              expect do
                find_by_testid('run-pipeline-button', text: 'New pipeline').click
                wait_for_requests
              end
                .to change { Ci::Pipeline.count }.by(1)

              expect(Ci::Pipeline.last.variables.map { |var| var.slice(:key, :secret_value) })
                .to eq [{ key: "key_name", secret_value: "value" }.with_indifferent_access]
            end
          end
        end

        context 'without gitlab-ci.yml' do
          before do
            find_by_testid('run-pipeline-button', text: 'New pipeline').click
            wait_for_requests
          end

          it { expect(page).to have_content('Missing CI config file') }

          it 'creates a pipeline after first request failed and a valid gitlab-ci.yml file is available when trying again' do
            stub_ci_pipeline_to_return_yaml_file

            expect do
              find_by_testid('run-pipeline-button', text: 'New pipeline').click
              wait_for_requests
            end
              .to change { Ci::Pipeline.count }.by(1)
          end
        end
      end
    end

    describe 'Reset runner caches' do
      let(:project) { create(:project, :repository) }

      before do
        create(:ci_empty_pipeline, status: 'success', project: project, sha: project.commit.id, ref: 'master')
        project.add_maintainer(user)
        visit project_pipelines_path(project)
      end

      it 'has a clear caches button' do
        expect(page).to have_button 'Clear runner caches'
      end

      describe 'user clicks the button' do
        context 'when project already has jobs_cache_index' do
          before do
            project.update!(jobs_cache_index: 1)
          end

          it 'increments jobs_cache_index' do
            click_button 'Clear runner caches'
            wait_for_requests
            expect(find_by_testid('alert-info')).to have_content 'Project cache successfully reset.'
          end
        end

        context 'when project does not have jobs_cache_index' do
          it 'sets jobs_cache_index to 1' do
            click_button 'Clear runner caches'
            wait_for_requests
            expect(find_by_testid('alert-info')).to have_content 'Project cache successfully reset.'
          end
        end
      end
    end

    describe 'Run Pipelines' do
      let(:project) { create(:project, :repository) }

      before do
        visit new_project_pipeline_path(project)
      end

      describe 'new pipeline page' do
        it 'has field to add a new pipeline' do
          expect(page).to have_button project.default_branch
          expect(page).to have_content('Run for')
        end
      end

      describe 'find pipelines' do
        it 'shows filtered pipelines', :js do
          click_button project.default_branch
          send_keys('2-mb-file')

          expect_listbox_item('2-mb-file')
        end
      end
    end

    describe 'Empty State' do
      let_it_be_with_reload(:project) { create(:project, :repository) }

      before do
        visit project_pipelines_path(project)

        wait_for_requests
      end

      it 'renders empty state' do
        expect(page).to have_content 'Try test template'
      end

      it 'does not show Jenkins Migration Prompt' do
        expect(page).not_to have_content _('Migrate to GitLab CI/CD from Jenkins')
      end
    end

    describe 'Jenkins migration prompt' do
      let_it_be_with_reload(:project) { create(:project, :repository) }

      before do
        allow_next_instance_of(Repository) do |instance|
          allow(instance).to receive(:jenkinsfile?).and_return(true)
        end
      end

      context 'when jenkinsfile is present' do
        it 'shows Jenkins Migration Prompt' do
          visit project_pipelines_path(project)

          wait_for_requests

          expect(page).to have_content _('Migrate to GitLab CI/CD from Jenkins')
          expect(page).to have_content _('Start with a migration plan')
        end
      end

      context 'when gitlab ci file is present' do
        let_it_be(:project) { create(:project, :small_repo, files: { '.gitlab-ci.yml' => 'test' }) }

        it 'does not show migration prompt' do
          expect_not_to_show_prompt(project)
        end
      end

      context 'when AutoDevops is enabled' do
        before do
          project.update!(auto_devops_attributes: { enabled: true })
        end

        it 'does not show migration prompt' do
          expect_not_to_show_prompt(project)
        end
      end

      def expect_not_to_show_prompt(project)
        visit project_pipelines_path(project)

        wait_for_requests

        expect(page).not_to have_content _('Migrate to GitLab CI/CD from Jenkins')
        expect(page).not_to have_content _('Start with a migration plan')
      end
    end
  end

  context 'when user is not logged in' do
    before do
      project.update!(auto_devops_attributes: { enabled: false })
      visit project_pipelines_path(project)
    end

    context 'when project is public' do
      let(:project) { create(:project, :public, :repository) }

      context 'without pipelines' do
        it { expect(page).to have_content 'This project is not currently set up to run pipelines.' }
      end
    end

    context 'when project is private' do
      let(:project) { create(:project, :private, :repository) }

      it 'redirects the user to sign_in and displays the flash alert' do
        expect(page).to have_content 'You need to sign in'
        expect(page).to have_current_path("/users/sign_in")
      end
    end
  end

  def visit_project_pipelines(**query)
    visit project_pipelines_path(project, query)
    wait_for_requests
  end
end
