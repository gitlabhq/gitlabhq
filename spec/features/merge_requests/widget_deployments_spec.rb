require 'spec_helper'

feature 'Widget Deployments Header', feature: true, js: true do
  include WaitForAjax

  describe 'when deployed to an environment' do
    given(:user) { create(:user) }
    given(:project) { merge_request.target_project }
    given(:merge_request) { create(:merge_request, :merged) }
    given(:environment) { create(:environment, project: project) }
    given(:role) { :developer }
    given!(:deployment) do
      create(:deployment, environment: environment, sha: project.commit('master').id)
    end
    given!(:manual) { }

    background do
      login_as(user)
      project.team << [user, role]
      visit namespace_project_merge_request_path(project.namespace, project, merge_request)
    end

    scenario 'displays that the environment is deployed' do
      wait_for_ajax

      expect(page).to have_content("Deployed to #{environment.name}")
      expect(find('.ci_widget > span > span')['data-title']).to eq(deployment.created_at.to_time.in_time_zone.to_s(:medium))
    end

    context 'with stop action' do
      given(:pipeline) { create(:ci_pipeline, project: project) }
      given(:build) { create(:ci_build, pipeline: pipeline) }
      given(:manual) { create(:ci_build, :manual, pipeline: pipeline, name: 'close_app') }
      given(:deployment) { create(:deployment, environment: environment, deployable: build, on_stop: 'close_app') }

      background do
        wait_for_ajax
      end

      scenario 'does show stop button' do
        expect(page).to have_link('Stop environment')
      end

      scenario 'does start build when stop button clicked' do
        click_link('Stop environment')

        expect(page).to have_content('close_app')
      end

      context 'for reporter' do
        given(:role) { :reporter }

        scenario 'does not show stop button' do
          expect(page).not_to have_link('Stop environment')
        end
      end
    end
  end
end
