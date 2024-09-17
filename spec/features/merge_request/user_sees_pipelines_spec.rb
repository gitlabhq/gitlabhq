# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees pipelines', :js, feature_category: :code_review_workflow do
  context 'with feature flag `mr_pipelines_graphql turned off`' do
    before do
      stub_feature_flags(mr_pipelines_graphql: false)
    end

    describe 'pipeline tab' do
      let(:merge_request) { create(:merge_request) }
      let(:project) { merge_request.target_project }
      let(:user) { project.creator }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      context 'with pipelines' do
        let!(:pipeline) do
          create(
            :ci_pipeline,
            :success,
            project: merge_request.source_project,
            ref: merge_request.source_branch,
            sha: merge_request.diff_head_sha
          )
        end

        let!(:manual_job) { create(:ci_build, :manual, name: 'job1', stage: 'deploy', pipeline: pipeline) }

        let!(:job) { create(:ci_build, :success, name: 'job2', stage: 'test', pipeline: pipeline) }

        before do
          merge_request.update_attribute(:head_pipeline_id, pipeline.id)
        end

        it 'pipelines table displays correctly' do
          visit project_merge_request_path(project, merge_request)

          expect(page.find('.ci-widget')).to have_content('passed')

          page.within('.merge-request-tabs') do
            click_link('Pipelines')
          end

          wait_for_requests

          within_testid('pipeline-table-row', match: :first) do
            expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Passed')
            expect(page).to have_content(pipeline.id)
            expect(page).to have_css('[data-testid="pipeline-mini-graph"]')
            expect(page).to have_css('[data-testid="pipelines-manual-actions-dropdown"]')
            expect(page).to have_css('[data-testid="pipeline-multi-actions-dropdown"]')
          end
        end

        context 'with a detached merge request pipeline' do
          let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }

          it 'displays the "Run pipeline" button' do
            visit project_merge_request_path(project, merge_request)

            page.within('.merge-request-tabs') do
              click_link('Pipelines')
            end

            wait_for_requests

            expect(find_by_testid('run_pipeline_button')).to have_text('Run pipeline')
          end
        end

        context 'with a merged results pipeline' do
          let(:merge_request) { create(:merge_request, :with_merge_request_pipeline) }

          it 'displays the "Run pipeline" button' do
            visit project_merge_request_path(project, merge_request)

            page.within('.merge-request-tabs') do
              click_link('Pipelines')
            end

            wait_for_requests

            expect(find_by_testid('run_pipeline_button')).to have_text('Run pipeline')
          end
        end
      end

      context 'without pipelines' do
        before do
          visit project_merge_request_path(project, merge_request)
        end

        it 'user visits merge request page' do
          page.within('.merge-request-tabs') do
            expect(page).to have_link('Pipelines')
          end
        end

        it 'shows empty state with run pipeline button' do
          page.within('.merge-request-tabs') do
            click_link('Pipelines')
          end

          expect(page).to have_content('There are currently no pipelines.')
          expect(find_by_testid('run_pipeline_button')).to have_text('Run pipeline')
        end
      end
    end

    describe 'fork MRs in parent project', :sidekiq_inline do
      include ProjectForksHelper

      let_it_be(:parent_project) { create(:project, :public, :repository) }
      let_it_be(:forked_project) { fork_project(parent_project, developer_in_fork, repository: true, target_project: create(:project, :public, :repository)) }
      let_it_be(:developer_in_parent) { create(:user) }
      let_it_be(:developer_in_fork) { create(:user) }
      let_it_be(:reporter_in_parent_and_developer_in_fork) { create(:user) }

      let(:merge_request) do
        create(
          :merge_request,
          :with_detached_merge_request_pipeline,
          source_project: forked_project,
          source_branch: 'feature',
          target_project: parent_project,
          target_branch: 'master'
        )
      end

      let(:config) do
        { test: { script: 'test', rules: [{ if: '$CI_MERGE_REQUEST_ID' }] } }
      end

      before_all do
        parent_project.add_developer(developer_in_parent)
        parent_project.add_reporter(reporter_in_parent_and_developer_in_fork)
        forked_project.add_developer(developer_in_fork)
        forked_project.add_developer(reporter_in_parent_and_developer_in_fork)
      end

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(config))
        sign_in(actor)
      end

      # rubocop:disable Cop/DestroyAll -- cannot delete due to not-null constraint
      after do
        parent_project.all_pipelines.destroy_all
        forked_project.all_pipelines.destroy_all
      end
      # rubocop:enable Cop/DestroyAll

      context 'when actor is a developer in parent project' do
        let(:actor) { developer_in_parent }

        it 'creates a pipeline in the parent project when user proceeds with the warning' do
          visit project_merge_request_path(parent_project, merge_request)

          create_merge_request_pipeline
          act_on_security_warning(action: 'Run pipeline')

          check_pipeline(expected_project: parent_project)
          check_head_pipeline(expected_project: parent_project)
        end

        it 'does not create a pipeline in the parent project when user cancels the action', :clean_gitlab_redis_cache, :clean_gitlab_redis_shared_state do
          visit project_merge_request_path(parent_project, merge_request)

          create_merge_request_pipeline
          act_on_security_warning(action: 'Cancel')

          check_no_new_pipeline_created
        end
      end

      context 'when actor is a developer in fork project' do
        let(:actor) { developer_in_fork }

        it 'creates a pipeline in the fork project' do
          visit project_merge_request_path(parent_project, merge_request)

          create_merge_request_pipeline

          check_pipeline(expected_project: forked_project)
          check_head_pipeline(expected_project: forked_project)
        end
      end

      context 'when actor is a reporter in parent project and a developer in fork project' do
        let(:actor) { reporter_in_parent_and_developer_in_fork }

        it 'creates a pipeline in the fork project' do
          visit project_merge_request_path(parent_project, merge_request)

          create_merge_request_pipeline

          check_pipeline(expected_project: forked_project)
          check_head_pipeline(expected_project: forked_project)
        end
      end

      def create_merge_request_pipeline
        page.within('.merge-request-tabs') { click_link('Pipelines') }
        click_on('Run pipeline')
      end

      def check_pipeline(expected_project:)
        page.within('.ci-table') do
          expect(page).to have_selector('[data-testid="pipeline-table-row"]', count: 2)

          page.within(first('[data-testid="pipeline-table-row"]')) do
            page.within('.pipeline-tags') do
              expect(find_by_testid('pipeline-url-link')[:href]).to include(expected_project.full_path)
              expect(page).to have_content('merge request')
            end
            page.within('.pipeline-triggerer') do
              expect(page).to have_link(href: user_path(actor))
            end
          end
        end
      end

      def check_head_pipeline(expected_project:)
        page.within('.merge-request-tabs') { click_link('Overview') }

        page.within('.ci-widget-content') do
          expect(page.find('.pipeline-id')[:href]).to include(expected_project.full_path)
        end
      end

      def act_on_security_warning(action:)
        page.within('#create-pipeline-for-fork-merge-request-modal') do
          expect(page).to have_content('Are you sure you want to run this pipeline?')
          click_button(action)
        end
      end

      def check_no_new_pipeline_created
        page.within('.ci-table') do
          expect(page).to have_selector('[data-testid="pipeline-table-row"]', count: 1)
        end
      end
    end

    describe 'race condition' do
      let(:project) { create(:project, :repository) }
      let(:user) { create(:user) }
      let(:build_push_data) { { ref: 'feature', checkout_sha: TestEnv::BRANCH_SHA['feature'] } }

      let(:merge_request_params) do
        { "source_branch" => "feature", "source_project_id" => project.id,
          "target_branch" => "master", "target_project_id" => project.id, "title" => "A" }
      end

      before do
        project.add_maintainer(user)
        sign_in user
      end

      context 'when pipeline and merge request were created simultaneously', :delete do
        before do
          stub_ci_pipeline_to_return_yaml_file

          threads = []

          threads << Thread.new do
            Sidekiq::Worker.skipping_transaction_check do
              @merge_request = MergeRequests::CreateService.new(project: project, current_user: user, params: merge_request_params).execute
            end
          end

          threads << Thread.new do
            Sidekiq::Worker.skipping_transaction_check do
              @pipeline = Ci::CreatePipelineService.new(project, user, build_push_data).execute(:push).payload
            end
          end

          threads.each { |thr| thr.join }
        end

        it 'user sees pipeline in merge request widget', :sidekiq_might_not_need_inline do
          visit project_merge_request_path(project, @merge_request)

          expect(page.find(".ci-widget")).to have_content(TestEnv::BRANCH_SHA['feature'])
          expect(page.find(".ci-widget")).to have_content("##{@pipeline.id}")
        end
      end
    end
  end
end
