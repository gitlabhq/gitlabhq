require 'spec_helper'

feature 'Widget Deployments Header', feature: true, js: true do
  include WaitForAjax

  describe 'when deployed to an environment' do
    let(:project)       { merge_request.target_project }
    let(:merge_request) { create(:merge_request, :merged) }
    let(:environment)   { create(:environment, project: project) }
    let!(:deployment)   do
      create(:deployment, environment: environment, sha: project.commit('master').id)
    end

    before do
      login_as :admin
      visit namespace_project_merge_request_path(project.namespace, project, merge_request)
    end

    it 'displays that the environment is deployed' do
      wait_for_ajax
      expect(page).to have_content("Deployed to #{environment.name}")
    end
  end
end
