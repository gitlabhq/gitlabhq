require 'spec_helper'

describe "Pipelines" do
  include GitlabRoutingHelper

  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  before do
    login_as(user)
    project.team << [user, :developer]
  end

  describe 'GET /:project/pipelines' do
    let!(:pipeline) { create(:ci_commit, project: project, ref: 'master', status: 'running') }

    [:all, :running, :branches].each do |scope|
      context "displaying #{scope}" do
        let(:project) { create(:project) }

        before { visit namespace_project_pipelines_path(project.namespace, project, scope: scope) }

        it { expect(page).to have_content(pipeline.short_sha) }
      end
    end

    context 'anonymous access' do
      before { visit namespace_project_pipelines_path(project.namespace, project) }

      it { expect(page).to have_http_status(:success) }
    end

    context 'cancelable pipeline' do
      let!(:running) { create(:ci_build, :running, commit: pipeline, stage: 'test', commands: 'test') }

      before { visit namespace_project_pipelines_path(project.namespace, project) }

      it { expect(page).to have_link('Cancel') }
      it { expect(page).to have_selector('.ci-running') }

      context 'when canceling' do
        before { click_link('Cancel') }

        it { expect(page).to_not have_link('Cancel') }
        it { expect(page).to have_selector('.ci-canceled') }
      end
    end

    context 'retryable pipelines' do
      let!(:failed) { create(:ci_build, :failed, commit: pipeline, stage: 'test', commands: 'test') }

      before { visit namespace_project_pipelines_path(project.namespace, project) }

      it { expect(page).to have_link('Retry') }
      it { expect(page).to have_selector('.ci-failed') }

      context 'when retrying' do
        before { click_link('Retry') }

        it { expect(page).to_not have_link('Retry') }
        it { expect(page).to have_selector('.ci-pending') }
      end
    end

    context 'downloadable pipelines' do
      context 'with artifacts' do
        let!(:with_artifacts) { create(:ci_build, :artifacts, :success, commit: pipeline, name: 'rspec tests', stage: 'test') }

        before { visit namespace_project_pipelines_path(project.namespace, project) }

        it { expect(page).to have_selector('.build-artifacts') }
        it { expect(page).to have_link(with_artifacts.name) }
      end

      context 'without artifacts' do
        let!(:without_artifacts) { create(:ci_build, :success, commit: pipeline, name: 'rspec', stage: 'test') }

        it { expect(page).to_not have_selector('.build-artifacts') }
      end
    end
  end

  describe 'GET /:project/pipelines/:id' do
    let(:pipeline) { create(:ci_commit, project: project, ref: 'master') }

    before do
      @success = create(:ci_build, :success, commit: pipeline, stage: 'build', name: 'build')
      @failed = create(:ci_build, :failed, commit: pipeline, stage: 'test', name: 'test', commands: 'test')
      @running = create(:ci_build, :running, commit: pipeline, stage: 'deploy', name: 'deploy')
      @external = create(:generic_commit_status, status: 'success', commit: pipeline, name: 'jenkins', stage: 'external')
    end

    before { visit namespace_project_pipeline_path(project.namespace, project, pipeline) }

    it 'showing a list of builds' do
      expect(page).to have_content('Tests')
      expect(page).to have_content(@success.id)
      expect(page).to have_content('Deploy')
      expect(page).to have_content(@failed.id)
      expect(page).to have_content(@running.id)
      expect(page).to have_content(@external.id)
      expect(page).to have_content('Retry failed')
      expect(page).to have_content('Cancel running')
    end

    context 'retrying builds' do
      it { expect(page).to_not have_content('retried') }

      context 'when retrying' do
        before { click_on 'Retry failed' }

        it { expect(page).to_not have_content('Retry failed') }
        it { expect(page).to have_content('retried') }
      end
    end

    context 'canceling builds' do
      it { expect(page).to_not have_selector('.ci-canceled') }

      context 'when canceling' do
        before { click_on 'Cancel running' }

        it { expect(page).to_not have_content('Cancel running') }
        it { expect(page).to have_selector('.ci-canceled') }
      end
    end
  end

  describe 'POST /:project/pipelines' do
    let(:project) { create(:project) }

    before { visit new_namespace_project_pipeline_path(project.namespace, project) }

    context 'for valid commit' do
      before { fill_in('Create for', with: 'master') }

      context 'with gitlab-ci.yml' do
        before { stub_ci_commit_to_return_yaml_file }

        it { expect{ click_on 'Create pipeline' }.to change{ Ci::Commit.count }.by(1) }
      end

      context 'without gitlab-ci.yml' do
        before { click_on 'Create pipeline' }

        it { expect(page).to have_content('Missing .gitlab-ci.yml file') }
      end
    end

    context 'for invalid commit' do
      before do
        fill_in('Create for', with: 'invalid reference')
        click_on 'Create pipeline'
      end

      it { expect(page).to have_content('Reference not found') }
    end
  end
end
