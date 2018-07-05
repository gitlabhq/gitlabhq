require 'spec_helper'

describe 'Gcp Cluster', :js do
  include GoogleApi::CloudPlatformHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    gitlab_sign_in(user)
    allow(Projects::ClustersController).to receive(:STATUS_POLLING_INTERVAL) { 100 }
  end

  context 'when a user has a licence to use multiple clusers' do
    before do
      stub_licensed_features(multiple_clusters: true)
      visit project_clusters_path(project)

      click_link 'Add Kubernetes cluster'
      click_link 'Add existing cluster'
    end

    it 'user sees the "Environment scope" field' do
      expect(page).to have_css('#cluster_environment_scope')
    end
  end
end
