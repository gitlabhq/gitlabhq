# frozen_string_literal: true

require 'spec_helper'

describe 'Functions', :js do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    gitlab_sign_in(user)
  end

  shared_examples "it's missing knative installation" do
    before do
      visit project_serverless_functions_path(project)
    end

    it 'sees an empty state require Knative installation' do
      expect(page).to have_link('Install Knative')
      expect(page).to have_selector('.empty-state')
    end
  end

  context 'when user does not have a cluster and visits the serverless page' do
    it_behaves_like "it's missing knative installation"
  end

  context 'when the user does have a cluster and visits the serverless page' do
    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }

    it_behaves_like "it's missing knative installation"
  end

  context 'when the user has a cluster and knative installed and visits the serverless page' do
    let(:cluster) { create(:cluster, :project, :provided_by_gcp, projects: [project]) }
    let(:service) { cluster.platform_kubernetes }
    let(:environment) { create(:environment, project: project) }
    let!(:deployment) { create(:deployment, :success, cluster: cluster, environment: environment) }
    let(:knative_services_finder) { environment.knative_services_finder }
    let(:namespace) do
      create(:cluster_kubernetes_namespace,
        cluster: cluster,
        project: cluster.cluster_project.project,
        environment: environment)
    end

    before do
      allow(Clusters::KnativeServicesFinder)
        .to receive(:new)
        .and_return(knative_services_finder)
      synchronous_reactive_cache(knative_services_finder)
      stub_kubeclient_knative_services(stub_get_services_options)
      stub_kubeclient_service_pods(nil, namespace: namespace.namespace)
      visit project_serverless_functions_path(project)
    end

    context 'when there are no functions' do
      let(:stub_get_services_options) do
        {
          namespace: namespace.namespace,
          response: kube_response({ "kind" => "ServiceList", "items" => [] })
        }
      end

      it 'sees an empty listing of serverless functions' do
        expect(page).to have_selector('.empty-state')
        expect(page).not_to have_selector('.content-list')
      end
    end

    context 'when there are functions' do
      let(:stub_get_services_options) { { namespace: namespace.namespace } }

      it 'does not see an empty listing of serverless functions' do
        expect(page).not_to have_selector('.empty-state')
        expect(page).to have_selector('.content-list')
      end
    end
  end
end
