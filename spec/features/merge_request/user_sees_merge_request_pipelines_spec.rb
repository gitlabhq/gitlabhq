# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees pipelines triggered by merge request', :js do
  include ProjectForksHelper
  include TestReportsHelper

  let(:project) { create(:project, :public, :repository) }
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

  before do
    stub_application_setting(auto_devops_enabled: false)
    stub_ci_pipeline_yaml_file(YAML.dump(config))
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when a user created a merge request in the parent project' do
    let!(:merge_request) do
      create(:merge_request,
              source_project: project,
              target_project: project,
              source_branch: 'feature',
              target_branch: 'master')
    end

    let!(:push_pipeline) do
      Ci::CreatePipelineService.new(project, user, ref: 'feature')
        .execute(:push)
        .payload
    end

    let!(:detached_merge_request_pipeline) do
      Ci::CreatePipelineService.new(project, user, ref: 'feature')
        .execute(:merge_request_event, merge_request: merge_request)
        .payload
    end

    before do
      visit project_merge_request_path(project, merge_request)

      page.within('.merge-request-tabs') do
        click_link('Pipelines')
      end
    end

    it 'sees branch pipelines and detached merge request pipelines in correct order' do
      page.within('.ci-table') do
        expect(page).to have_selector('.ci-created', count: 2)
        expect(first('[data-testid="pipeline-url-link"]')).to have_content("##{detached_merge_request_pipeline.id}")
      end
    end

    it 'sees the latest detached merge request pipeline as the head pipeline', :sidekiq_might_not_need_inline do
      click_link "Overview"

      page.within('.ci-widget-content') do
        expect(page).to have_content("##{detached_merge_request_pipeline.id}")
      end
    end

    context 'when a user updated a merge request in the parent project', :sidekiq_might_not_need_inline do
      let!(:push_pipeline_2) do
        Ci::CreatePipelineService.new(project, user, ref: 'feature')
          .execute(:push)
          .payload
      end

      let!(:detached_merge_request_pipeline_2) do
        Ci::CreatePipelineService.new(project, user, ref: 'feature')
          .execute(:merge_request_event, merge_request: merge_request)
          .payload
      end

      before do
        visit project_merge_request_path(project, merge_request)

        page.within('.merge-request-tabs') do
          click_link('Pipelines')
        end
      end

      it 'sees branch pipelines and detached merge request pipelines in correct order' do
        page.within('.ci-table') do
          expect(page).to have_selector('.ci-pending', count: 4)

          expect(all('[data-testid="pipeline-url-link"]')[0])
            .to have_content("##{detached_merge_request_pipeline_2.id}")

          expect(all('[data-testid="pipeline-url-link"]')[1])
            .to have_content("##{detached_merge_request_pipeline.id}")

          expect(all('[data-testid="pipeline-url-link"]')[2])
            .to have_content("##{push_pipeline_2.id}")

          expect(all('[data-testid="pipeline-url-link"]')[3])
            .to have_content("##{push_pipeline.id}")
        end
      end

      it 'sees detached tag for detached merge request pipelines' do
        page.within('.ci-table') do
          expect(all('.pipeline-tags')[0])
            .to have_content("detached")

          expect(all('.pipeline-tags')[1])
            .to have_content("detached")

          expect(all('.pipeline-tags')[2])
            .not_to have_content("detached")

          expect(all('.pipeline-tags')[3])
            .not_to have_content("detached")
        end
      end

      it 'sees the latest detached merge request pipeline as the head pipeline' do
        click_link 'Overview'

        page.within('.ci-widget-content') do
          expect(page).to have_content("##{detached_merge_request_pipeline_2.id}")
        end
      end
    end

    context 'when a user merges a merge request in the parent project', :sidekiq_might_not_need_inline do
      before do
        click_link 'Overview'
        click_button 'Merge when pipeline succeeds'

        wait_for_requests
      end

      context 'when detached merge request pipeline is pending' do
        it 'waits the head pipeline' do
          expect(page).to have_content('to be merged automatically when the pipeline succeeds')
          expect(page).to have_link('Cancel')
        end
      end

      context 'when detached merge request pipeline succeeds' do
        before do
          detached_merge_request_pipeline.reload.succeed!

          wait_for_requests
        end

        it 'merges the merge request' do
          expect(page).to have_content('Merged by')
          expect(page).to have_button('Revert')
        end
      end

      context 'when branch pipeline succeeds' do
        before do
          click_link 'Overview'
          push_pipeline.reload.succeed!

          wait_for_requests
        end

        it 'waits the head pipeline' do
          expect(page).to have_content('to be merged automatically when the pipeline succeeds')
          expect(page).to have_link('Cancel')
        end
      end
    end

    context 'when there are no `merge_requests` keyword in .gitlab-ci.yml' do
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

      it 'sees a branch pipeline in pipeline tab' do
        page.within('.ci-table') do
          expect(page).to have_selector('.ci-created', count: 1)
          expect(first('[data-testid="pipeline-url-link"]')).to have_content("##{push_pipeline.id}")
        end
      end

      it 'sees the latest branch pipeline as the head pipeline', :sidekiq_might_not_need_inline do
        click_link 'Overview'

        page.within('.ci-widget-content') do
          expect(page).to have_content("##{push_pipeline.id}")
        end
      end
    end
  end

  context 'when a user created a merge request from a forked project to the parent project', :sidekiq_might_not_need_inline do
    let(:merge_request) do
      create(:merge_request,
              source_project: forked_project,
              target_project: project,
              source_branch: 'feature',
              target_branch: 'master')
    end

    let!(:push_pipeline) do
      Ci::CreatePipelineService.new(forked_project, user2, ref: 'feature')
        .execute(:push)
        .payload
    end

    let!(:detached_merge_request_pipeline) do
      Ci::CreatePipelineService.new(forked_project, user2, ref: 'feature')
        .execute(:merge_request_event, merge_request: merge_request)
        .payload
    end

    let(:forked_project) { fork_project(project, user2, repository: true) }
    let(:user2) { create(:user) }

    before do
      forked_project.add_maintainer(user2)

      visit project_merge_request_path(project, merge_request)

      page.within('.merge-request-tabs') do
        click_link('Pipelines')
      end
    end

    it 'sees branch pipelines and detached merge request pipelines in correct order' do
      page.within('.ci-table') do
        expect(page).to have_selector('.ci-pending', count: 2)
        expect(first('[data-testid="pipeline-url-link"]')).to have_content("##{detached_merge_request_pipeline.id}")
      end
    end

    it 'sees the latest detached merge request pipeline as the head pipeline' do
      click_link "Overview"

      page.within('.ci-widget-content') do
        expect(page).to have_content("##{detached_merge_request_pipeline.id}")
      end
    end

    it 'sees pipeline list in forked project' do
      visit project_pipelines_path(forked_project)

      expect(page).to have_selector('.ci-pending', count: 2)
    end

    context 'when a user updated a merge request from a forked project to the parent project' do
      let!(:push_pipeline_2) do
        Ci::CreatePipelineService.new(forked_project, user2, ref: 'feature')
          .execute(:push)
          .payload
      end

      let!(:detached_merge_request_pipeline_2) do
        Ci::CreatePipelineService.new(forked_project, user2, ref: 'feature')
          .execute(:merge_request_event, merge_request: merge_request)
          .payload
      end

      before do
        visit project_merge_request_path(project, merge_request)

        page.within('.merge-request-tabs') do
          click_link('Pipelines')
        end
      end

      it 'sees branch pipelines and detached merge request pipelines in correct order' do
        page.within('.ci-table') do
          expect(page).to have_selector('.ci-pending', count: 4)

          expect(all('[data-testid="pipeline-url-link"]')[0])
            .to have_content("##{detached_merge_request_pipeline_2.id}")

          expect(all('[data-testid="pipeline-url-link"]')[1])
            .to have_content("##{detached_merge_request_pipeline.id}")

          expect(all('[data-testid="pipeline-url-link"]')[2])
            .to have_content("##{push_pipeline_2.id}")

          expect(all('[data-testid="pipeline-url-link"]')[3])
            .to have_content("##{push_pipeline.id}")
        end
      end

      it 'sees detached tag for detached merge request pipelines' do
        page.within('.ci-table') do
          expect(all('.pipeline-tags')[0])
            .to have_content("detached")

          expect(all('.pipeline-tags')[1])
            .to have_content("detached")

          expect(all('.pipeline-tags')[2])
            .not_to have_content("detached")

          expect(all('.pipeline-tags')[3])
            .not_to have_content("detached")
        end
      end

      it 'sees the latest detached merge request pipeline as the head pipeline' do
        click_link "Overview"

        page.within('.ci-widget-content') do
          expect(page).to have_content("##{detached_merge_request_pipeline_2.id}")
        end
      end

      it 'sees pipeline list in forked project' do
        visit project_pipelines_path(forked_project)

        expect(page).to have_selector('.ci-pending', count: 4)
      end
    end

    context 'when the latest pipeline is running in the parent project' do
      before do
        Ci::CreatePipelineService.new(project, user, ref: 'feature')
          .execute(:merge_request_event, merge_request: merge_request)
      end

      context 'when the previous pipeline failed in the fork project' do
        before do
          detached_merge_request_pipeline.reload.drop!
        end

        context 'when the parent project enables pipeline must succeed' do
          before do
            project.update!(only_allow_merge_if_pipeline_succeeds: true)
          end

          it 'shows MWPS button' do
            visit project_merge_request_path(project, merge_request)

            expect(page).to have_button('Merge when pipeline succeeds')
          end
        end
      end
    end

    context 'when a user merges a merge request from a forked project to the parent project' do
      before do
        click_link("Overview")

        click_button 'Merge when pipeline succeeds'

        wait_for_requests
      end

      context 'when detached merge request pipeline is pending' do
        it 'waits the head pipeline' do
          expect(page).to have_content('to be merged automatically when the pipeline succeeds')
          expect(page).to have_link('Cancel')
        end
      end

      context 'when detached merge request pipeline succeeds' do
        before do
          detached_merge_request_pipeline.reload.succeed!

          wait_for_requests
        end

        it 'merges the merge request' do
          expect(page).to have_content('Merged by')
          expect(page).to have_button('Revert')
        end
      end

      context 'when branch pipeline succeeds' do
        before do
          push_pipeline.reload.succeed!

          wait_for_requests
        end

        it 'waits the head pipeline' do
          expect(page).to have_content('to be merged automatically when the pipeline succeeds')
          expect(page).to have_link('Cancel')
        end
      end
    end
  end
end
