require 'spec_helper'

feature 'Widget Deployments Header', js: true do
  describe 'when deployed to an environment' do
    given(:user) { create(:user) }
    given(:project) { merge_request.target_project }
    given(:merge_request) { create(:merge_request, :merged) }
    given(:environment) { create(:environment, project: project) }
    given(:role) { :developer }
    given(:sha) { project.commit('master').id }
    given!(:deployment) { create(:deployment, environment: environment, sha: sha) }
    given!(:manual) { }

    background do
      sign_in(user)
      project.team << [user, role]
      visit project_merge_request_path(project, merge_request)
    end

    scenario 'displays that the environment is deployed' do
      wait_for_requests

      expect(page).to have_content("Deployed to #{environment.name}")
      expect(find('.js-deploy-time')['data-title']).to eq(deployment.created_at.to_time.in_time_zone.to_s(:medium))
    end

    context 'with stop action' do
      given(:pipeline) { create(:ci_pipeline, project: project) }
      given(:build) { create(:ci_build, pipeline: pipeline) }
      given(:manual) { create(:ci_build, :manual, pipeline: pipeline, name: 'close_app') }
      given(:deployment) do
        create(:deployment, environment: environment, ref: merge_request.target_branch,
                            sha: sha, deployable: build, on_stop: 'close_app')
      end

      background do
        wait_for_requests
      end

      scenario 'does show stop button' do
        expect(page).to have_button('Stop environment')
      end

      scenario 'does start build when stop button clicked' do
        click_button('Stop environment')

        expect(page).to have_content('close_app')
      end

      context 'for reporter' do
        given(:role) { :reporter }

        scenario 'does not show stop button' do
          expect(page).not_to have_button('Stop environment')
        end
      end
    end
  end
end
