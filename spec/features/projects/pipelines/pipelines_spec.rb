# frozen_string_literal: true

require 'spec_helper'

describe 'Pipelines', :js do
  include ProjectForksHelper

  let(:project) { create(:project) }

  context 'when user is logged in' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
      project.add_developer(user)
      project.update!(auto_devops_attributes: { enabled: false })
    end

    describe 'GET /:project/pipelines' do
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

        it 'shows a tab for Pending pipelines and count' do
          expect(page.find('.js-pipelines-tab-pending').text).to include('Pending')
          expect(page.find('.js-pipelines-tab-pending .badge').text).to include('0')
        end

        it 'shows a tab for Running pipelines and count' do
          expect(page.find('.js-pipelines-tab-running').text).to include('Running')
          expect(page.find('.js-pipelines-tab-running .badge').text).to include('1')
        end

        it 'shows a tab for Finished pipelines and count' do
          expect(page.find('.js-pipelines-tab-finished').text).to include('Finished')
          expect(page.find('.js-pipelines-tab-finished .badge').text).to include('0')
        end

        it 'shows a tab for Branches' do
          expect(page.find('.js-pipelines-tab-branches').text).to include('Branches')
        end

        it 'shows a tab for Tags' do
          expect(page.find('.js-pipelines-tab-tags').text).to include('Tags')
        end

        it 'updates content when tab is clicked' do
          page.find('.js-pipelines-tab-pending').click
          wait_for_requests
          expect(page).to have_content('There are currently no pending pipelines.')
        end
      end

      context 'navigation links' do
        before do
          visit project_pipelines_path(project)
          wait_for_requests
        end

        it 'renders run pipeline link' do
          expect(page).to have_link('Run Pipeline')
        end

        it 'renders ci lint link' do
          expect(page).to have_link('CI Lint')
        end
      end

      context 'when pipeline is cancelable' do
        let!(:build) do
          create(:ci_build, pipeline: pipeline,
                            stage: 'test')
        end

        before do
          build.run
          visit_project_pipelines
        end

        it 'indicates that pipeline can be canceled' do
          expect(page).to have_selector('.js-pipelines-cancel-button')
          expect(page).to have_selector('.ci-running')
        end

        context 'when canceling' do
          before do
            find('.js-pipelines-cancel-button').click
            find('.js-modal-primary-action').click
            wait_for_requests
          end

          it 'indicated that pipelines was canceled', :sidekiq_might_not_need_inline do
            expect(page).not_to have_selector('.js-pipelines-cancel-button')
            expect(page).to have_selector('.ci-canceled')
          end
        end
      end

      context 'when pipeline is retryable', :sidekiq_might_not_need_inline do
        let!(:build) do
          create(:ci_build, pipeline: pipeline,
                            stage: 'test')
        end

        before do
          build.drop
          visit_project_pipelines
        end

        it 'indicates that pipeline can be retried' do
          expect(page).to have_selector('.js-pipelines-retry-button')
          expect(page).to have_selector('.ci-failed')
        end

        context 'when retrying' do
          before do
            find('.js-pipelines-retry-button').click
            wait_for_requests
          end

          it 'shows running pipeline that is not retryable' do
            expect(page).not_to have_selector('.js-pipelines-retry-button')
            expect(page).to have_selector('.ci-running')
          end
        end
      end

      context 'when pipeline is detached merge request pipeline' do
        let(:merge_request) do
          create(:merge_request,
            :with_detached_merge_request_pipeline,
            source_project: source_project,
            target_project: target_project)
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
              expect(page).to have_content('detached')
            end

            within '.branch-commit' do
              expect(page).to have_link(merge_request.iid,
                href: project_merge_request_path(project, merge_request))
            end

            within '.branch-commit' do
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
          create(:merge_request,
            :with_merge_request_pipeline,
            source_project: source_project,
            target_project: target_project,
            merge_sha: target_project.commit.sha)
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
              expect(page).not_to have_content('detached')
            end

            within '.branch-commit' do
              expect(page).to have_link(merge_request.iid,
                href: project_merge_request_path(project, merge_request))
            end

            within '.branch-commit' do
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
            %Q{span[data-original-title="#{pipeline.yaml_errors}"]})
        end

        it 'contains badge that indicates failure reason' do
          expect(page).to have_content 'error'
        end

        it 'contains badge with tooltip which contains failure reason' do
          expect(pipeline.failure_reason?).to eq true
          expect(page).to have_selector(
            %Q{span[data-original-title="#{pipeline.present.failure_reason}"]})
        end
      end

      context 'with manual actions' do
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
          expect(page).to have_selector('.dropdown-new.btn.btn-default .icon-play')
        end

        it 'has link to the manual action' do
          find('.js-pipeline-dropdown-manual-actions').click

          expect(page).to have_button('manual build')
        end

        context 'when manual action was played' do
          before do
            find('.js-pipeline-dropdown-manual-actions').click
            click_button('manual build')
          end

          it 'enqueues manual action job' do
            expect(page).to have_selector('.js-pipeline-dropdown-manual-actions:disabled')
          end
        end
      end

      context 'when there is a delayed job' do
        let!(:delayed_job) do
          create(:ci_build, :scheduled,
            pipeline: pipeline,
            name: 'delayed job',
            stage: 'test')
        end

        before do
          visit_project_pipelines
        end

        it 'has a dropdown for actionable jobs' do
          expect(page).to have_selector('.dropdown-new.btn.btn-default .icon-play')
        end

        it "has link to the delayed job's action" do
          find('.js-pipeline-dropdown-manual-actions').click

          time_diff = [0, delayed_job.scheduled_at - Time.now].max
          expect(page).to have_button('delayed job')
          expect(page).to have_content(Time.at(time_diff).utc.strftime("%H:%M:%S"))
        end

        context 'when delayed job is expired already' do
          let!(:delayed_job) do
            create(:ci_build, :expired_scheduled,
              pipeline: pipeline,
              name: 'delayed job',
              stage: 'test')
          end

          it "shows 00:00:00 as the remaining time" do
            find('.js-pipeline-dropdown-manual-actions').click

            expect(page).to have_content("00:00:00")
          end
        end

        context 'when user played a delayed job immediately' do
          before do
            find('.js-pipeline-dropdown-manual-actions').click
            page.accept_confirm { click_button('delayed job') }
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
            expect(page).to have_selector('.ci-preparing')
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
            expect(page).to have_selector('.ci-running')
          end

          context 'when canceling' do
            before do
              find('.js-pipelines-cancel-button').click
              find('.js-modal-primary-action').click
            end

            it 'indicates that pipeline was canceled', :sidekiq_might_not_need_inline do
              expect(page).not_to have_selector('.js-pipelines-cancel-button')
              expect(page).to have_selector('.ci-canceled')
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
            expect(page).to have_selector('.ci-failed')
          end
        end
      end

      context 'downloadable pipelines' do
        context 'with artifacts' do
          let!(:with_artifacts) do
            create(:ci_build, :artifacts, :success,
              pipeline: pipeline,
              name: 'rspec tests',
              stage: 'test')
          end

          before do
            visit_project_pipelines
          end

          it 'has artifacts' do
            expect(page).to have_selector('.build-artifacts')
          end

          it 'has artifacts download dropdown' do
            find('.js-pipeline-dropdown-download').click

            expect(page).to have_link(with_artifacts.name)
          end

          it 'has download attribute on download links' do
            find('.js-pipeline-dropdown-download').click
            expect(page).to have_selector('a', text: 'Download')
            page.all('.build-artifacts a', text: 'Download').each do |link|
              expect(link[:download]).to eq ''
            end
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

          it { expect(page).not_to have_selector('.build-artifacts') }
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

          it { expect(page).not_to have_selector('.build-artifacts') }
        end

        context 'with trace artifact' do
          before do
            create(:ci_build, :success, :trace_artifact, pipeline: pipeline)

            visit_project_pipelines
          end

          it 'does not show trace artifact as artifacts' do
            expect(page).not_to have_selector('.build-artifacts')
          end
        end
      end

      context 'mini pipeline graph' do
        let!(:build) do
          create(:ci_build, :pending, pipeline: pipeline,
                                      stage: 'build',
                                      name: 'build')
        end

        before do
          visit_project_pipelines
        end

        it 'renders a mini pipeline graph' do
          expect(page).to have_selector('.js-mini-pipeline-graph')
          expect(page).to have_selector('.js-builds-dropdown-button')
        end

        context 'when clicking a stage badge' do
          it 'opens a dropdown' do
            find('.js-builds-dropdown-button').click

            expect(page).to have_link build.name
          end

          it 'is possible to cancel pending build' do
            find('.js-builds-dropdown-button').click
            find('.js-ci-action').click
            wait_for_requests

            expect(build.reload).to be_canceled
          end
        end

        context 'for a failed pipeline' do
          let!(:build) do
            create(:ci_build, :failed, pipeline: pipeline,
                                       stage: 'build',
                                       name: 'build')
          end

          it 'displays the failure reason' do
            find('.js-builds-dropdown-button').click

            within('.js-builds-dropdown-list') do
              build_element = page.find('.mini-pipeline-graph-dropdown-item')
              expect(build_element['data-original-title']).to eq('build - failed - (unknown failure)')
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

          expect(page).to have_selector('.gl-pagination .page', count: 2)
        end

        it 'shows updated content' do
          visit project_pipelines_path(project)
          wait_for_requests
          page.find('.js-next-button .page-link').click

          expect(page).to have_selector('.gl-pagination .page', count: 2)
        end
      end
    end

    describe 'GET /:project/pipelines/show' do
      let(:project) { create(:project, :repository) }

      let(:pipeline) do
        create(:ci_empty_pipeline,
              project: project,
              sha: project.commit.id,
              user: user)
      end

      before do
        create_build('build', 0, 'build', :success)
        create_build('test', 1, 'rspec 0:2', :pending)
        create_build('test', 1, 'rspec 1:2', :running)
        create_build('test', 1, 'spinach 0:2', :created)
        create_build('test', 1, 'spinach 1:2', :created)
        create_build('test', 1, 'audit', :created)
        create_build('deploy', 2, 'production', :created)

        create(:generic_commit_status, pipeline: pipeline, stage: 'external', name: 'jenkins', stage_idx: 3)

        visit project_pipeline_path(project, pipeline)
        wait_for_requests
      end

      it 'shows a graph with grouped stages' do
        expect(page).to have_css('.js-pipeline-graph')

        # header
        expect(page).to have_text("##{pipeline.id}")
        expect(page).to have_selector(%Q(img[alt$="#{pipeline.user.name}'s avatar"]))
        expect(page).to have_link(pipeline.user.name, href: user_path(pipeline.user))

        # stages
        expect(page).to have_text('Build')
        expect(page).to have_text('Test')
        expect(page).to have_text('Deploy')
        expect(page).to have_text('External')

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

    describe 'POST /:project/pipelines' do
      let(:project) { create(:project, :repository) }

      before do
        visit new_project_pipeline_path(project)
      end

      context 'for valid commit', :js do
        before do
          click_button project.default_branch

          page.within '.dropdown-menu' do
            click_link 'master'
          end
        end

        context 'with gitlab-ci.yml' do
          before do
            stub_ci_pipeline_to_return_yaml_file
          end

          it 'creates a new pipeline' do
            expect { click_on 'Run Pipeline' }
              .to change { Ci::Pipeline.count }.by(1)

            expect(Ci::Pipeline.last).to be_web
          end

          context 'when variables are specified' do
            it 'creates a new pipeline with variables' do
              page.within '.ci-variable-row-body' do
                fill_in "Input variable key", with: "key_name"
                fill_in "Input variable value", with: "value"
              end

              expect { click_on 'Run Pipeline' }
                .to change { Ci::Pipeline.count }.by(1)

              expect(Ci::Pipeline.last.variables.map { |var| var.slice(:key, :secret_value) })
                .to eq [{ key: "key_name", secret_value: "value" }.with_indifferent_access]
            end
          end
        end

        context 'without gitlab-ci.yml' do
          before do
            click_on 'Run Pipeline'
          end

          it { expect(page).to have_content('Missing CI config file') }
          it 'creates a pipeline after first request failed and a valid gitlab-ci.yml file is available when trying again' do
            click_button project.default_branch

            stub_ci_pipeline_to_return_yaml_file

            page.within '.dropdown-menu' do
              click_link 'master'
            end

            expect { click_on 'Run Pipeline' }
              .to change { Ci::Pipeline.count }.by(1)
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
          expect(page).to have_selector('.js-branch-select')
          expect(find('.js-branch-select')).to have_content project.default_branch
          expect(page).to have_content('Run for')
        end
      end

      describe 'find pipelines' do
        it 'shows filtered pipelines', :js do
          click_button project.default_branch

          page.within '.dropdown-menu' do
            find('.dropdown-input-field').native.send_keys('fix')

            page.within '.dropdown-content' do
              expect(page).to have_content('fix')
            end
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
        expect(page).to have_button 'Clear Runner Caches'
      end

      describe 'user clicks the button' do
        context 'when project already has jobs_cache_index' do
          before do
            project.update(jobs_cache_index: 1)
          end

          it 'increments jobs_cache_index' do
            click_button 'Clear Runner Caches'
            wait_for_requests
            expect(page.find('.flash-notice')).to have_content 'Project cache successfully reset.'
          end
        end

        context 'when project does not have jobs_cache_index' do
          it 'sets jobs_cache_index to 1' do
            click_button 'Clear Runner Caches'
            wait_for_requests
            expect(page.find('.flash-notice')).to have_content 'Project cache successfully reset.'
          end
        end
      end
    end

    describe 'Empty State' do
      let(:project) { create(:project, :repository) }

      before do
        visit project_pipelines_path(project)
      end

      it 'renders empty state' do
        expect(page).to have_content 'Build with confidence'
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
        expect(page.current_path).to eq("/users/sign_in")
      end
    end
  end

  def visit_project_pipelines(**query)
    visit project_pipelines_path(project, query)
    wait_for_requests
  end
end
