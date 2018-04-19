require 'rails_helper'

describe 'Merge request > User sees deployment widget', :js do
  describe 'when deployed to an environment' do
    let(:user) { create(:user) }
    let(:project) { merge_request.target_project }
    let(:merge_request) { create(:merge_request, :merged) }
    let(:environment) { create(:environment, project: project) }
    let(:role) { :developer }
    let(:sha) { project.commit('master').id }
    let!(:deployment) { create(:deployment, environment: environment, sha: sha) }
    let!(:manual) { }

    before do
      project.add_user(user, role)
      sign_in(user)
      visit project_merge_request_path(project, merge_request)
      wait_for_requests
    end

    it 'displays that the environment is deployed' do
      wait_for_requests

      expect(page).to have_content("Deployed to #{environment.name}")
      expect(find('.js-deploy-time')['data-original-title']).to eq(deployment.created_at.to_time.in_time_zone.to_s(:medium))
    end

    context 'with stop action' do
      let(:pipeline) { create(:ci_pipeline, project: project) }
      let(:build) { create(:ci_build, pipeline: pipeline) }
      let(:manual) { create(:ci_build, :manual, pipeline: pipeline, name: 'close_app') }
      let(:deployment) do
        create(:deployment, environment: environment, ref: merge_request.target_branch,
                            sha: sha, deployable: build, on_stop: 'close_app')
      end

      before do
        wait_for_requests
      end

      it 'does start build when stop button clicked' do
        accept_confirm { click_button('Stop environment') }

        expect(page).to have_content('close_app')
      end

      context 'for reporter' do
        let(:role) { :reporter }

        it 'does not show stop button' do
          expect(page).not_to have_button('Stop environment')
        end
      end
    end
  end
end
