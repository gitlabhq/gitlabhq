require 'spec_helper'

describe 'Functions', :js do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    gitlab_sign_in(user)
  end

  context 'when user does not have a cluster and visits the serverless page' do
    before do
      visit project_serverless_functions_path(project)
    end

    it 'sees an empty state' do
      expect(page).to have_link('Install Knative')
      expect(page).to have_selector('.empty-state')
    end
  end

  context 'when the user does have a cluster and visits the serverless page' do
    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }

    before do
      visit project_serverless_functions_path(project)
    end

    it 'sees an empty state' do
      expect(page).to have_link('Install Knative')
      expect(page).to have_selector('.empty-state')
    end
  end

  context 'when the user has a cluster and knative installed and visits the serverless page' do
    let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:knative) { create(:clusters_applications_knative, :installed, cluster: cluster) }
    let(:project) { knative.cluster.project }

    before do
      visit project_serverless_functions_path(project)
    end

    it 'sees an empty listing of serverless functions' do
      expect(page).to have_selector('.gl-responsive-table-row')
    end
  end
end
