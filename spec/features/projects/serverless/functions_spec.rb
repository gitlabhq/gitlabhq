# frozen_string_literal: true

require 'spec_helper'

describe 'Functions', :js do
  include KubernetesHelpers

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
    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:service) { cluster.platform_kubernetes }
    let(:knative) { create(:clusters_applications_knative, :installed, cluster: cluster) }
    let(:project) { knative.cluster.project }

    before do
      stub_kubeclient_knative_services
      stub_kubeclient_service_pods
      visit project_serverless_functions_path(project)
    end

    it 'sees an empty listing of serverless functions' do
      expect(page).to have_selector('.empty-state')
    end
  end
end
