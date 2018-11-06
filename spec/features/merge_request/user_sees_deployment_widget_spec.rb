require 'rails_helper'

describe 'Merge request > User sees deployment widget', :js do
  describe 'when deployed to an environment' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, :merged, source_project: project) }
    let(:environment) { create(:environment, project: project) }
    let(:role) { :developer }
    let(:ref) { merge_request.target_branch }
    let(:sha) { project.commit(ref).id }
    let(:pipeline) { create(:ci_pipeline_without_jobs, sha: sha, project: project, ref: ref) }
    let(:build)    { create(:ci_build, :success, pipeline: pipeline) }
    let!(:deployment) { create(:deployment, :succeed, environment: environment, sha: sha, ref: ref, deployable: build) }
    let!(:manual) { }

    before do
      merge_request.update!(merge_commit_sha: sha)
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
      let(:manual) { create(:ci_build, :manual, pipeline: pipeline, name: 'close_app') }

      before do
        deployment.update!(on_stop: manual.name)
        wait_for_requests
      end

      it 'does start build when stop button clicked' do
        accept_confirm { find('.js-stop-env').click }

        expect(page).to have_content('close_app')
      end

      context 'for reporter' do
        let(:role) { :reporter }

        it 'does not show stop button' do
          expect(page).not_to have_selector('.js-stop-env')
        end
      end
    end
  end
end
