require 'spec_helper'

describe 'Pipeline', :js do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_developer(user)
  end

  shared_context 'pipeline builds' do
    let!(:build_passed) do
      create(:ci_build, :success,
             pipeline: pipeline, stage: 'build', name: 'build')
    end

    let!(:build_failed) do
      create(:ci_build, :failed,
             pipeline: pipeline, stage: 'test', name: 'test', commands: 'test')
    end

    let!(:build_running) do
      create(:ci_build, :running,
             pipeline: pipeline, stage: 'deploy', name: 'deploy')
    end

    let!(:build_manual) do
      create(:ci_build, :manual,
             pipeline: pipeline, stage: 'deploy', name: 'manual-build')
    end

    let!(:build_external) do
      create(:generic_commit_status, status: 'success',
                                     pipeline: pipeline,
                                     name: 'jenkins',
                                     stage: 'external',
                                     target_url: 'http://gitlab.com/status')
    end
  end

  describe 'GET /:project/pipelines/:id' do
    include_context 'pipeline builds'

    let(:project) { create(:project, :repository) }
    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id, user: user) }

    before do
      visit project_pipeline_path(project, pipeline)
    end

    it 'shows the pipeline graph' do
      expect(page).to have_selector('.pipeline-visualization')
      expect(page).to have_content('Build')
      expect(page).to have_content('Test')
      expect(page).to have_content('Deploy')
      expect(page).to have_content('Retry')
      expect(page).to have_content('Cancel running')
    end

    it 'shows Pipeline tab pane as active' do
      expect(page).to have_css('#js-tab-pipeline.active')
    end

    describe 'pipeline graph' do
      context 'when pipeline has running builds' do
        it 'shows a running icon and a cancel action for the running build' do
          page.within('#ci-badge-deploy') do
            expect(page).to have_selector('.js-ci-status-icon-running')
            expect(page).to have_selector('.js-icon-cancel')
            expect(page).to have_content('deploy')
          end
        end

        it 'should be possible to cancel the running build' do
          find('#ci-badge-deploy .ci-action-icon-container').click

          expect(page).not_to have_content('Cancel running')
        end
      end

      context 'when pipeline has successful builds' do
        it 'shows the success icon and a retry action for the successful build' do
          page.within('#ci-badge-build') do
            expect(page).to have_selector('.js-ci-status-icon-success')
            expect(page).to have_content('build')
          end

          page.within('#ci-badge-build .ci-action-icon-container.js-icon-retry') do
            expect(page).to have_selector('svg')
          end
        end

        it 'should be possible to retry the success job' do
          find('#ci-badge-build .ci-action-icon-container').click

          expect(page).not_to have_content('Retry job')
        end
      end

      context 'when pipeline has failed builds' do
        it 'shows the failed icon and a retry action for the failed build' do
          page.within('#ci-badge-test') do
            expect(page).to have_selector('.js-ci-status-icon-failed')
            expect(page).to have_content('test')
          end

          page.within('#ci-badge-test .ci-action-icon-container.js-icon-retry') do
            expect(page).to have_selector('svg')
          end
        end

        it 'should be possible to retry the failed build' do
          find('#ci-badge-test .ci-action-icon-container').click

          expect(page).not_to have_content('Retry job')
        end

        it 'should include the failure reason' do
          page.within('#ci-badge-test') do
            build_link = page.find('.js-pipeline-graph-job-link')
            expect(build_link['data-original-title']).to eq('test - failed <br> (unknown failure)')
          end
        end
      end

      context 'when pipeline has manual jobs' do
        it 'shows the skipped icon and a play action for the manual build' do
          page.within('#ci-badge-manual-build') do
            expect(page).to have_selector('.js-ci-status-icon-manual')
            expect(page).to have_content('manual')
          end

          page.within('#ci-badge-manual-build .ci-action-icon-container.js-icon-play') do
            expect(page).to have_selector('svg')
          end
        end

        it 'should be possible to play the manual job' do
          find('#ci-badge-manual-build .ci-action-icon-container').click

          expect(page).not_to have_content('Play job')
        end
      end

      context 'when pipeline has external job' do
        it 'shows the success icon and the generic comit status build' do
          expect(page).to have_selector('.js-ci-status-icon-success')
          expect(page).to have_content('jenkins')
          expect(page).to have_link('jenkins', href: 'http://gitlab.com/status')
        end
      end
    end

    context 'page tabs' do
      it 'shows Pipeline and Jobs tabs with link' do
        expect(page).to have_link('Pipeline')
        expect(page).to have_link('Jobs')
      end

      it 'shows counter in Jobs tab' do
        expect(page.find('.js-builds-counter').text).to eq(pipeline.total_size.to_s)
      end

      it 'shows Pipeline tab as active' do
        expect(page).to have_css('.js-pipeline-tab-link.active')
      end
    end

    context 'retrying jobs' do
      it { expect(page).not_to have_content('retried') }

      context 'when retrying' do
        before do
          find('.js-retry-button').click
        end

        it { expect(page).not_to have_content('Retry') }
      end
    end

    context 'canceling jobs' do
      it { expect(page).not_to have_selector('.ci-canceled') }

      context 'when canceling' do
        before do
          click_on 'Cancel running'
        end

        it { expect(page).not_to have_content('Cancel running') }
      end
    end
  end

  context 'when user does not have access to read jobs' do
    before do
      project.update(public_builds: false)
    end

    describe 'GET /:project/pipelines/:id' do
      include_context 'pipeline builds'

      let(:project) { create(:project, :repository) }
      let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id, user: user) }

      before do
        visit project_pipeline_path(project, pipeline)
      end

      it 'shows the pipeline graph' do
        expect(page).to have_selector('.pipeline-visualization')
        expect(page).to have_content('Build')
        expect(page).to have_content('Test')
        expect(page).to have_content('Deploy')
        expect(page).to have_content('Retry')
        expect(page).to have_content('Cancel running')
      end

      it 'should not link to job' do
        expect(page).not_to have_selector('.js-pipeline-graph-job-link')
      end
    end
  end

  describe 'GET /:project/pipelines/:id/builds' do
    include_context 'pipeline builds'

    let(:project) { create(:project, :repository) }
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
      expect(page).to have_content('Cancel running')
      expect(page).to have_link('Play')
    end

    it 'shows jobs tab pane as active' do
      expect(page).to have_css('#js-tab-builds.active')
    end

    context 'page tabs' do
      it 'shows Pipeline and Jobs tabs with link' do
        expect(page).to have_link('Pipeline')
        expect(page).to have_link('Jobs')
      end

      it 'shows counter in Jobs tab' do
        expect(page.find('.js-builds-counter').text).to eq(pipeline.total_size.to_s)
      end

      it 'shows Jobs tab as active' do
        expect(page).to have_css('li.js-builds-tab-link.active')
      end
    end

    context 'retrying jobs' do
      it { expect(page).not_to have_content('retried') }

      context 'when retrying' do
        before do
          find('.js-retry-button').click
        end

        it { expect(page).not_to have_content('Retry') }
      end
    end

    context 'canceling jobs' do
      it { expect(page).not_to have_selector('.ci-canceled') }

      context 'when canceling' do
        before do
          click_on 'Cancel running'
        end

        it { expect(page).not_to have_content('Cancel running') }
      end
    end

    context 'playing manual job' do
      before do
        within '.pipeline-holder' do
          click_link('Play')
        end
      end

      it { expect(build_manual.reload).to be_pending }
    end

    context 'failed jobs' do
      it 'displays a tooltip with the failure reason' do
        page.within('.ci-table') do
          failed_job_link = page.find('.ci-failed')
          expect(failed_job_link[:title]).to eq('Failed <br> (unknown failure)')
        end
      end
    end
  end

  describe 'GET /:project/pipelines/:id/failures' do
    let(:project) { create(:project, :repository) }
    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }
    let(:pipeline_failures_page) { failures_project_pipeline_path(project, pipeline) }
    let!(:failed_build) { create(:ci_build, :failed, pipeline: pipeline) }

    context 'with failed build' do
      before do
        failed_build.trace.set('4 examples, 1 failure')

        visit pipeline_failures_page
      end

      it 'shows jobs tab pane as active' do
        expect(page).to have_content('Failed Jobs')
        expect(page).to have_css('#js-tab-failures.active')
      end

      it 'lists failed builds' do
        expect(page).to have_content(failed_build.name)
        expect(page).to have_content(failed_build.stage)
      end

      it 'shows build failure logs' do
        expect(page).to have_content('4 examples, 1 failure')
      end
    end

    context 'when missing build logs' do
      before do
        visit pipeline_failures_page
      end

      it 'includes failed jobs' do
        expect(page).to have_content('No job trace')
      end
    end

    context 'without failures' do
      before do
        failed_build.update!(status: :success)

        visit pipeline_failures_page
      end

      it 'displays the pipeline graph' do
        expect(current_path).to eq(pipeline_path(pipeline))
        expect(page).not_to have_content('Failed Jobs')
        expect(page).to have_selector('.pipeline-visualization')
      end
    end
  end
end
