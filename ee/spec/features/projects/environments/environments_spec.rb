# frozen_string_literal: true

require 'spec_helper'

describe 'Environments page', :js do
  let(:project) { create(:project, :repository) }
  let!(:environment) { create(:environment, name: 'production', project: project) }
  let(:user) { create(:user) }

  before do
    stub_feature_flags(protected_environments: true)
    allow(License).to receive(:feature_available?).and_call_original
    allow(License).to receive(:feature_available?).with(:protected_environments).and_return(true)
    project.add_maintainer(user)

    sign_in(user)
  end

  context 'when an environment is protected and user has access to it' do
    before do
      create(:protected_environment,
             project: project, name: 'production',
             authorize_user_to_deploy: user)
    end

    context 'when environment has manual actions' do
      let!(:pipeline) { create(:ci_pipeline, project: project) }
      let!(:build) { create(:ci_build, pipeline: pipeline) }

      let!(:deployment) do
        create(:deployment,
               environment: environment, deployable: build,
               sha: project.commit.id)
      end

      let!(:action) do
        create(:ci_build, :manual,
               pipeline: pipeline, name: 'deploy to production',
               environment: 'production')
      end

      before do
        visit project_environments_path(project)
        wait_for_requests
      end

      it 'shows an enabled play button' do
        find('.js-dropdown-play-icon-container').click
        play_button = %q{button[class="js-manual-action-link no-btn btn"]}

        expect(page).to have_selector(play_button)
      end

      it 'shows a stop button' do
        stop_button_selector = %q{button[data-original-title="Stop environment"]}

        expect(page).to have_selector(stop_button_selector)
      end

      context 'with external_url' do
        let(:environment) { create(:environment, project: project, external_url: 'https://git.gitlab.com') }

        it 'shows an external link button' do
          expect(page).to have_link(nil, href: environment.external_url)
        end
      end

      context 'when terminal is available' do
        let(:cluster) { create(:cluster, :provided_by_gcp, projects: [create(:project, :repository)]) }
        let(:project) { cluster.project }

        it 'shows a terminal button' do
          expect(page).to have_link(nil, href: terminal_project_environment_path(project, environment))
        end
      end
    end

    context 'when environment can be rollback' do
      let!(:pipeline) { create(:ci_pipeline, :success, project: project) }
      let!(:build) { create(:ci_build, :success, pipeline: pipeline, environment: 'production') }

      let!(:deployment) do
        create(:deployment,
               environment: environment, deployable: build,
               sha: project.commit.id)
      end

      before do
        visit project_environments_path(project)
        wait_for_requests
      end

      it 'shows re deploy button' do
        redeploy_button_selector = %q{button[data-original-title="Re-deploy to environment"]}

        expect(page).to have_selector(redeploy_button_selector)
      end
    end
  end

  context 'when environment is protected and user does not have access to it' do
    before do
      create(:protected_environment,
             project: project, name: 'production',
             authorize_user_to_deploy: create(:user))
    end

    context 'when environment has manual actions' do
      let!(:pipeline) { create(:ci_pipeline, project: project) }
      let!(:build) { create(:ci_build, pipeline: pipeline, environment: 'production') }

      let!(:deployment) do
        create(:deployment,
               environment: environment, deployable: build,
               sha: project.commit.id)
      end

      let!(:action) do
        create(:ci_build, :manual,
               pipeline: pipeline, name: 'deploy to production',
               environment: 'production')
      end

      before do
        visit project_environments_path(project)
        wait_for_requests
      end

      it 'show a disabled play button' do
        find('.js-dropdown-play-icon-container').click
        disabled_play_button = %q{button[class="js-manual-action-link no-btn btn disabled"]}

        expect(page).to have_selector(disabled_play_button)
      end

      it 'does not show a stop button' do
        stop_button_selector = %q{button[data-original-title="Stop environment"]}

        expect(page).not_to have_selector(stop_button_selector)
      end

      context 'with external_url' do
        let(:environment) { create(:environment, project: project, external_url: 'https://git.gitlab.com') }

        it 'shows an external link button' do
          expect(page).to have_link(nil, href: environment.external_url)
        end
      end

      context 'when terminal is available' do
        let(:cluster) { create(:cluster, :provided_by_gcp, projects: [create(:project, :repository)]) }
        let(:project) { cluster.project }

        it 'does not shows a terminal button' do
          expect(page).not_to have_link(nil, href: terminal_project_environment_path(project, environment))
        end
      end
    end

    context 'when environment can be rollback' do
      let!(:pipeline) { create(:ci_pipeline, :success, project: project) }
      let!(:build) { create(:ci_build, :success, pipeline: pipeline, environment: 'production') }

      let!(:deployment) do
        create(:deployment,
               environment: environment, deployable: build,
               sha: project.commit.id)
      end

      before do
        visit project_environments_path(project)
        wait_for_requests
      end

      it 'does not show a re deploy button' do
        redeploy_button_selector = %q{button[data-original-title="Re-deploy to environment"]}

        expect(page).not_to have_selector(redeploy_button_selector)
      end
    end
  end
end
