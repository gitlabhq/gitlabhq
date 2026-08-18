# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees pipelines triggered by merge request', :js, feature_category: :code_review_workflow do
  include ProjectForksHelper
  using RSpec::Parameterized::TableSyntax

  # We need a new project object in most tests: some examples merge the merge request
  # (`feature` into `master`), which would leave later examples with no diff on a shared repo.
  let(:project) do
    create(:project, :public, :repository, only_allow_merge_if_pipeline_succeeds: true)
  end

  let(:user) { project.creator }

  let(:config) do
    {
      build: {
        script: 'build'
      },
      test: {
        script: 'test',
        only: ['merge_requests']
      },
      deploy: {
        script: 'deploy',
        except: ['merge_requests']
      }
    }
  end

  shared_context 'with a push pipeline' do
    # Eager: head-pipeline linking only works if the merge request exists before the pipeline.
    let!(:merge_request) do
      create(
        :merge_request,
        source_project: source_project,
        target_project: project,
        source_branch: 'feature',
        target_branch: 'master'
      )
    end

    let!(:push_pipeline) { create_push_pipeline(source_project, source_user, ref: 'feature') }
  end

  shared_context 'when the merge request is in the parent project with a push pipeline' do
    let(:source_project) { project }
    let(:source_user) { user }
    let(:initial_pipeline_status) { 'Created' }

    include_context 'with a push pipeline'
  end

  shared_context 'when the merge request is from a forked project with a push pipeline' do
    let(:user2) { create(:user) }

    let(:forked_project) { fork_project(project, user2, repository: true) }

    before do
      forked_project.add_maintainer(user2)
    end

    let(:source_project) { forked_project }
    let(:source_user) { user2 }
    let(:initial_pipeline_status) { 'Pending' }

    include_context 'with a push pipeline'
  end

  shared_examples 'shows only the branch pipeline' do
    it 'sees a branch pipeline in the pipelines tab' do
      visit_merge_request_pipelines_tab(merge_request)

      page.within('.ci-table') do
        expect(page).to have_selector(
          '[data-label="Status"] [data-testid="ci-icon"]', text: initial_pipeline_status, count: 1)
        expect(first('[data-testid="pipeline-url-link"]')).to have_content("##{push_pipeline.id}")
      end
    end

    it 'sees the branch pipeline as the head pipeline', :sidekiq_inline do
      visit project_merge_request_path(project, merge_request)

      page.within('.ci-widget-content') do
        expect(page).to have_content("##{push_pipeline.id}")
      end
    end
  end

  shared_examples 'shows the two pipelines for the merge request' do
    it 'sees branch and detached pipelines in the correct order' do
      visit_merge_request_pipelines_tab(merge_request)

      page.within('.ci-table') do
        status_icon_selector = '[data-label="Status"] [data-testid="ci-icon"]'
        expect(page).to have_selector(status_icon_selector, text: initial_pipeline_status, count: 2)

        within('[data-testid="pipeline-table-row"]:nth-child(1)') do
          expect(page).to have_content("##{detached_merge_request_pipeline.id}")
        end
      end
    end

    it 'sees the detached pipeline as the head pipeline', :sidekiq_inline do
      visit project_merge_request_path(project, merge_request)

      page.within('.ci-widget-content') do
        expect(page).to have_content("##{detached_merge_request_pipeline.id}")
      end
    end
  end

  shared_examples 'shows all four pipelines for the merge request' do
    it 'sees branch and detached pipelines in the correct order', :sidekiq_inline do
      visit_merge_request_pipelines_tab(merge_request)

      page.within('.ci-table') do
        expected_detached_mr_tag = 'merge request'

        expect(page).to have_selector('[data-label="Status"] [data-testid="ci-icon"]', text: 'Pending', count: 4)

        within('[data-testid="pipeline-table-row"]:nth-child(1)') do
          expect(page).to have_content("##{detached_merge_request_pipeline_2.id}")
          expect(page).to have_content(expected_detached_mr_tag)
        end

        within('[data-testid="pipeline-table-row"]:nth-child(2)') do
          expect(page).to have_content("##{detached_merge_request_pipeline.id}")
          expect(page).to have_content(expected_detached_mr_tag)
        end

        within('[data-testid="pipeline-table-row"]:nth-child(3)') do
          expect(page).to have_content("##{push_pipeline_2.id}")
          expect(page).not_to have_content(expected_detached_mr_tag)
        end

        within('[data-testid="pipeline-table-row"]:nth-child(4)') do
          expect(page).to have_content("##{push_pipeline.id}")
          expect(page).not_to have_content(expected_detached_mr_tag)
        end
      end
    end

    it 'sees the latest detached pipeline as the head pipeline', :sidekiq_inline do
      visit project_merge_request_path(project, merge_request)

      page.within('.ci-widget-content') do
        expect(page).to have_content("##{detached_merge_request_pipeline_2.id}")
      end
    end
  end

  # These examples wait on the merge widget's polled state (5s+ backoff, see
  # STATE_QUERY_POLLING_INTERVAL_DEFAULT in mr_widget constants.js), which can exceed
  # Capybara's local timeout. If these fail locally, rerun with CI_SERVER=1.
  shared_examples 'waits to auto-merge the merge request' do
    before do
      visit project_merge_request_path(project, merge_request)
      click_button 'Set to auto-merge'

      find_button('Cancel auto-merge')
    end

    context 'when the detached pipeline is pending' do
      it 'waits for the head pipeline' do
        expect(page).to have_content 'to be merged automatically when all merge checks pass'
        expect(page).to have_button('Cancel auto-merge')
      end
    end

    context 'when the branch pipeline succeeds' do
      before do
        push_pipeline.reload.succeed!
      end

      it 'waits for the head pipeline' do
        expect(page).to have_content 'to be merged automatically when all merge checks pass'
        expect(page).to have_button('Cancel auto-merge')
      end
    end

    context 'when the detached pipeline succeeds' do
      before do
        detached_merge_request_pipeline.reload.succeed!
      end

      it 'merges the merge request', :sidekiq_inline do
        expect(merge_request.reload).to be_merged
        page.refresh

        expect(page).to have_content('Merged by')
        expect(page).to have_button('Revert')
      end
    end
  end

  where(:mr_pipelines_graphql) do
    [true, false]
  end

  with_them do
    before do
      # rubocop:disable RSpec/AvoidConditionalStatements
      stub_licensed_features(merge_request_approvers: true) if Gitlab.ee?
      # rubocop:enable RSpec/AvoidConditionalStatements

      stub_feature_flags(mr_pipelines_graphql: mr_pipelines_graphql)

      stub_application_setting(auto_devops_enabled: false)
      stub_ci_pipeline_yaml_file(YAML.dump(config))
      project.add_maintainer(user)
      sign_in(user)
    end

    context 'when the merge request is in the parent project' do
      include_context 'when the merge request is in the parent project with a push pipeline'

      context 'with a detached merge request pipeline' do
        let!(:detached_merge_request_pipeline) do
          create_detached_pipeline(source_project, source_user, ref: 'feature', merge_request: merge_request)
        end

        include_examples 'shows the two pipelines for the merge request'

        context 'when the user sets the merge request to auto-merge' do
          include_examples 'waits to auto-merge the merge request'
        end

        context 'when the merge request is updated with a second push and detached pipeline' do
          let!(:push_pipeline_2) { create_push_pipeline(source_project, source_user, ref: 'feature') }

          let!(:detached_merge_request_pipeline_2) do
            create_detached_pipeline(source_project, source_user, ref: 'feature', merge_request: merge_request)
          end

          include_examples 'shows all four pipelines for the merge request'
        end
      end

      context 'when .gitlab-ci.yml has no `merge_requests` rule' do
        let(:config) do
          {
            build: {
              script: 'build'
            },
            test: {
              script: 'test'
            },
            deploy: {
              script: 'deploy'
            }
          }
        end

        include_examples 'shows only the branch pipeline'
      end
    end

    context 'when the merge request is from a forked project', :sidekiq_inline do
      include_context 'when the merge request is from a forked project with a push pipeline'

      context 'with a detached merge request pipeline' do
        let!(:detached_merge_request_pipeline) do
          create_detached_pipeline(source_project, source_user, ref: 'feature', merge_request: merge_request)
        end

        include_examples 'shows the two pipelines for the merge request'

        context 'when the user sets the merge request to auto-merge' do
          include_examples 'waits to auto-merge the merge request'
        end

        it 'sees the pipeline list on the forked project page' do
          visit project_pipelines_path(forked_project)

          expect(page).to have_selector('[data-label="Status"] [data-testid="ci-icon"]', text: 'Pending', count: 2)
        end

        context 'when the merge request is updated with a second push and detached pipeline' do
          let!(:push_pipeline_2) { create_push_pipeline(source_project, source_user, ref: 'feature') }

          let!(:detached_merge_request_pipeline_2) do
            create_detached_pipeline(source_project, source_user, ref: 'feature', merge_request: merge_request)
          end

          include_examples 'shows all four pipelines for the merge request'

          it 'sees the pipeline list on the forked project page' do
            visit project_pipelines_path(forked_project)

            expect(page).to have_selector('[data-label="Status"] [data-testid="ci-icon"]', text: 'Pending', count: 4)
          end
        end

        context 'when the latest pipeline in the parent project is still running while the fork pipeline failed' do
          before do
            create(:ci_pipeline,
              source: :merge_request_event,
              project: project,
              ref: 'feature',
              sha: merge_request.diff_head_sha,
              user: user,
              merge_request: merge_request,
              status: :pending)
            merge_request.update_head_pipeline
            detached_merge_request_pipeline.reload.drop!
          end

          context 'when the parent project enables pipeline must succeed', :request_store do
            # Same merge-widget polling latency noted above; rerun with CI_SERVER=1 if this fails locally.
            it 'shows Set to auto-merge button' do
              visit project_merge_request_path(project, merge_request)

              expect(page).to have_button('Set to auto-merge')
            end
          end
        end
      end

      context 'when .gitlab-ci.yml has no `merge_requests` rule' do
        let(:config) do
          {
            build: {
              script: 'build'
            },
            test: {
              script: 'test'
            },
            deploy: {
              script: 'deploy'
            }
          }
        end

        include_examples 'shows only the branch pipeline'
      end
    end
  end

  def visit_merge_request_pipelines_tab(merge_request)
    visit project_merge_request_path(merge_request.target_project, merge_request)

    page.within('.merge-request-tabs') do
      click_link('Pipelines')
    end
  end

  def create_push_pipeline(pipeline_project, pipeline_user, ref:)
    Ci::CreatePipelineService.new(pipeline_project, pipeline_user, ref: ref).execute(:push).payload
  end

  def create_detached_pipeline(pipeline_project, pipeline_user, ref:, merge_request:)
    Ci::CreatePipelineService.new(pipeline_project, pipeline_user, ref: ref)
      .execute(:merge_request_event, merge_request: merge_request).payload
  end
end
