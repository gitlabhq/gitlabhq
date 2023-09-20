# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees deployment widget', :js, feature_category: :continuous_delivery do
  include Spec::Support::Helpers::ModalHelpers

  describe 'when merge request has associated environments' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, :merged, source_project: project) }
    let(:environment) { create(:environment, project: project) }
    let(:role) { :developer }
    let(:ref) { merge_request.target_branch }
    let(:sha) { project.commit(ref).id }
    let(:pipeline) { create(:ci_pipeline, sha: sha, project: project, ref: ref) }
    let!(:manual) {}
    let(:build) { create(:ci_build, :with_deployment, environment: environment.name, pipeline: pipeline) }
    let!(:deployment) { build.deployment }

    def assert_env_widget(text, env_name)
      expect(find('.js-deploy-env-name')[:title]).to have_text(env_name)
      expect(page).to have_content(text)
    end

    before do
      merge_request.update!(merge_commit_sha: sha)
      project.add_member(user, role)
      sign_in(user)
    end

    context 'when deployment succeeded' do
      before do
        build.success!
      end

      it 'displays that the environment is deployed' do
        visit project_merge_request_path(project, merge_request)
        wait_for_requests

        assert_env_widget("Deployed to", environment.name)
        expect(find('.js-deploy-time')['title']).to eq(deployment.created_at.to_time.in_time_zone.to_fs(:medium))
      end

      context 'when a user created a new merge request with the same SHA' do
        let(:pipeline2) { create(:ci_pipeline, sha: sha, project: project, ref: 'video') }
        let(:environment2) { create(:environment, project: project) }
        let!(:build2) { create(:ci_build, :with_deployment, :success, environment: environment2.name, pipeline: pipeline2) }

        it 'displays one environment which is related to the pipeline' do
          visit project_merge_request_path(project, merge_request)
          wait_for_requests

          expect(page).to have_selector('.js-deployment-info', count: 1)
          expect(find('.js-deploy-env-name')[:title]).to have_text(environment.name)
          expect(find('.js-deploy-env-name')[:title]).not_to have_text(environment2.name)
        end
      end
    end

    context 'when deployment failed' do
      before do
        build.drop!
      end

      it 'displays that the deployment failed' do
        visit project_merge_request_path(project, merge_request)
        wait_for_requests

        assert_env_widget("Failed to deploy to", environment.name)
        expect(page).not_to have_css('.js-deploy-time')
      end
    end

    context 'when deployment running' do
      before do
        build.run!
      end

      it 'displays that the running deployment' do
        visit project_merge_request_path(project, merge_request)
        wait_for_requests

        assert_env_widget("Deploying to", environment.name)
        expect(page).not_to have_css('.js-deploy-time')
      end
    end

    context 'when deployment will happen' do
      let(:build) { create(:ci_build, :with_deployment, environment: environment.name, pipeline: pipeline) }
      let!(:deployment) { build.deployment }

      it 'displays that the environment name' do
        visit project_merge_request_path(project, merge_request)
        wait_for_requests

        assert_env_widget("Will deploy to", environment.name)
        expect(page).not_to have_css('.js-deploy-time')
      end
    end

    context 'when deployment was cancelled' do
      before do
        build.cancel!
      end

      it 'displays that the environment name' do
        visit project_merge_request_path(project, merge_request)
        wait_for_requests

        assert_env_widget("Canceled deployment to", environment.name)
        expect(page).not_to have_css('.js-deploy-time')
      end
    end

    context 'with stop action' do
      let(:manual) do
        create(:ci_build, :manual, pipeline: pipeline, name: 'close_app', environment: environment.name)
      end

      before do
        build.success!
        deployment.update!(on_stop: manual.name)
        visit project_merge_request_path(project, merge_request)
        wait_for_requests
      end

      it 'displays the re-deploy button' do
        accept_gl_confirm(button_text: 'Stop environment') do
          find('.js-stop-env').click
        end

        expect(page).to have_selector('.js-redeploy-action')
      end

      context 'for reporter' do
        let(:role) { :reporter }

        it 'does not show stop button' do
          expect(page).not_to have_selector('.js-stop-env')
        end
      end
    end

    context 'with redeploy action' do
      before do
        build.success!
        environment.update!(state: 'stopped')
        visit project_merge_request_path(project, merge_request)
        wait_for_requests
      end

      it 'begins redeploying the deployment' do
        accept_gl_confirm(button_text: 'Re-deploy') do
          find('.js-redeploy-action').click
        end

        wait_for_requests

        expect(page).to have_content('Will deploy to')
      end
    end
  end
end
