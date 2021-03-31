# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Clusters', :js do
  include GoogleApi::CloudPlatformHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    gitlab_sign_in(user)
  end

  context 'when user does not have a cluster and visits cluster index page' do
    before do
      visit project_clusters_path(project)
    end

    it 'sees empty state' do
      expect(page).to have_link('Integrate with a cluster certificate')
      expect(page).to have_selector('.empty-state')
    end
  end

  context 'when user has a cluster' do
    before do
      allow_any_instance_of(Clusters::Cluster).to receive(:retrieve_connection_status).and_return(:connected)
    end

    context 'when user adds an existing cluster' do
      before do
        create(:cluster, :provided_by_user, name: 'default-cluster', environment_scope: '*', projects: [project])
        visit project_clusters_path(project)
      end

      it 'user sees an add cluster button' do
        expect(page).to have_selector('.js-add-cluster:not(.readonly)')
      end

      context 'when user filled form with environment scope' do
        before do
          click_link 'Connect cluster with certificate'
          click_link 'Connect existing cluster'
          fill_in 'cluster_name', with: 'staging-cluster'
          fill_in 'cluster_environment_scope', with: 'staging/*'
          click_button 'Add Kubernetes cluster'
        end

        it 'user sees a cluster details page' do
          expect(page.find_field('cluster[name]').value).to eq('staging-cluster')
          expect(page.find_field('cluster[environment_scope]').value).to eq('staging/*')
        end
      end

      context 'when user updates environment scope' do
        before do
          click_link 'default-cluster'
          fill_in 'cluster_environment_scope', with: 'production/*'
          within '.js-cluster-details-form' do
            click_button 'Save changes'
          end
        end

        it 'updates the environment scope' do
          expect(page.find_field('cluster[environment_scope]').value).to eq('production/*')
        end
      end

      context 'when user updates duplicated environment scope' do
        before do
          click_link 'Connect cluster with certificate'
          click_link 'Connect existing cluster'
          fill_in 'cluster_name', with: 'staging-cluster'
          fill_in 'cluster_environment_scope', with: '*'
          fill_in 'cluster_platform_kubernetes_attributes_api_url', with: 'https://0.0.0.0'
          fill_in 'cluster_platform_kubernetes_attributes_token', with: 'token'

          click_button 'Add Kubernetes cluster'
        end

        it 'users sees an environment scope validation error' do
          expect(page).to have_content('cannot add duplicated environment scope')
        end
      end
    end

    context 'when user adds a Google Kubernetes Engine cluster' do
      before do
        allow_any_instance_of(Projects::ClustersController)
          .to receive(:token_in_session).and_return('token')
        allow_any_instance_of(Projects::ClustersController)
          .to receive(:expires_at_in_session).and_return(1.hour.since.to_i.to_s)

        allow_any_instance_of(Projects::ClustersController).to receive(:authorize_google_project_billing)
        allow_any_instance_of(Projects::ClustersController).to receive(:google_project_billing_status).and_return(true)

        allow_any_instance_of(GoogleApi::CloudPlatform::Client)
          .to receive(:projects_zones_clusters_create) do
          OpenStruct.new(
            self_link: 'projects/gcp-project-12345/zones/us-central1-a/operations/ope-123',
            status: 'RUNNING'
          )
        end

        allow(WaitForClusterCreationWorker).to receive(:perform_in).and_return(nil)

        create(:cluster, :provided_by_gcp, name: 'default-cluster', environment_scope: '*', projects: [project])
        visit project_clusters_path(project)
      end

      it 'user sees a add cluster button' do
        expect(page).to have_selector('.js-add-cluster:not(.readonly)')
      end

      context 'when user filled form with environment scope' do
        before do
          click_link 'Connect cluster with certificate'
          click_link 'Create new cluster'
          click_link 'Google GKE'

          sleep 2 # wait for ajax
          execute_script('document.querySelector(".js-gcp-project-id-dropdown input").setAttribute("type", "text")')
          execute_script('document.querySelector(".js-gcp-zone-dropdown input").setAttribute("type", "text")')
          execute_script('document.querySelector(".js-gcp-machine-type-dropdown input").setAttribute("type", "text")')
          execute_script('document.querySelector(".js-gke-cluster-creation-submit").removeAttribute("disabled")')

          fill_in 'cluster_name', with: 'staging-cluster'
          fill_in 'cluster_environment_scope', with: 'staging/*'
          fill_in 'cluster[provider_gcp_attributes][gcp_project_id]', with: 'gcp-project-123'
          fill_in 'cluster[provider_gcp_attributes][zone]', with: 'us-central1-a'
          fill_in 'cluster[provider_gcp_attributes][machine_type]', with: 'n1-standard-2'
          click_button 'Create Kubernetes cluster'

          # The frontend won't show the details until the cluster is
          # created, and we don't want to make calls out to GCP.
          provider = Clusters::Cluster.last.provider
          provider.make_created
        end

        it 'user sees a cluster details page' do
          expect(page).to have_content('GitLab Integration')
          expect(page.find_field('cluster[environment_scope]').value).to eq('staging/*')
        end
      end

      context 'when user updates environment scope' do
        before do
          click_link 'default-cluster'
          fill_in 'cluster_environment_scope', with: 'production/*'
          within ".js-cluster-details-form" do
            click_button 'Save changes'
          end
        end

        it 'updates the environment scope' do
          expect(page.find_field('cluster[environment_scope]').value).to eq('production/*')
        end
      end

      context 'when user updates duplicated environment scope' do
        before do
          click_link 'Connect cluster with certificate'
          click_link 'Create new cluster'
          click_link 'Google GKE'

          sleep 2 # wait for ajax
          execute_script('document.querySelector(".js-gcp-project-id-dropdown input").setAttribute("type", "text")')
          execute_script('document.querySelector(".js-gcp-zone-dropdown input").setAttribute("type", "text")')
          execute_script('document.querySelector(".js-gcp-machine-type-dropdown input").setAttribute("type", "text")')
          execute_script('document.querySelector(".js-gke-cluster-creation-submit").removeAttribute("disabled")')

          fill_in 'cluster_name', with: 'staging-cluster'
          fill_in 'cluster_environment_scope', with: '*'
          fill_in 'cluster[provider_gcp_attributes][gcp_project_id]', with: 'gcp-project-123'
          fill_in 'cluster[provider_gcp_attributes][zone]', with: 'us-central1-a'
          fill_in 'cluster[provider_gcp_attributes][machine_type]', with: 'n1-standard-2'
          click_button 'Create Kubernetes cluster'
        end

        it 'users sees an environment scope validation error' do
          expect(page).to have_content('cannot add duplicated environment scope')
        end
      end
    end
  end

  context 'when user has a cluster and visits cluster index page' do
    let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }

    before do
      visit project_clusters_path(project)
    end

    it 'user sees a table with one cluster' do
      expect(page).to have_selector('[data-testid="cluster_list_table"] tbody tr', count: 1)
    end

    context 'when user clicks on a cluster' do
      before do
        click_link cluster.name
      end

      it 'user sees a cluster details page' do
        expect(page).to have_button('Save')
        expect(page.find(:css, '.cluster-name').value).to eq(cluster.name)
      end
    end
  end

  context 'user visits create cluster page' do
    before do
      visit project_clusters_path(project)

      click_link 'Integrate with a cluster certificate'
      click_link 'Create new cluster'
    end

    it 'user sees a link to create a GKE cluster' do
      expect(page).to have_link('Google GKE')
    end

    it 'user sees a link to create an EKS cluster' do
      expect(page).to have_link('Amazon EKS')
    end
  end
end
