require 'spec_helper'

feature 'User Cluster', :js do
  include GoogleApi::CloudPlatformHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    gitlab_sign_in(user)
    allow(Projects::ClustersController).to receive(:STATUS_POLLING_INTERVAL) { 100 }
  end

  context 'when user does not have a cluster and visits cluster index page' do
    before do
      visit project_clusters_path(project)

      click_link 'Add an existing cluster'
    end

    context 'when user filled form with valid parameters' do
      before do
        fill_in 'cluster_provider_gcp_attributes_gcp_project_id', with: 'gcp-project-123'
        fill_in 'cluster_platform_kubernetes_attributes_api_url', with: 'http://example.com'
        fill_in 'cluster_platform_kubernetes_attributes_token', with: 'my-token'
        fill_in 'cluster_name', with: 'dev-cluster'
        click_button 'Create cluster'
      end

      it 'user sees a cluster details page and creation status' do
        expect(page).to have_content('Cluster was successfully created on Google Container Engine')
      end
    end

    context 'when user filled form with invalid parameters' do
      before do
        click_button 'Create cluster'
      end

      it 'user sees a validation error' do
        expect(page).to have_css('#error_explanation')
      end
    end
  end

  context 'when user does have a cluster and visits cluster page' do
    let(:cluster) { create(:cluster, :provided_by_user, projects: [project]) }

    before do
      visit project_cluster_path(project, cluster)
    end

    it 'user sees a cluster details page' do
      expect(page).to have_button('Save')
      expect(page.find(:css, '.cluster-name').value).to eq(cluster.name)
    end

    context 'when user disables the cluster' do
      before do
        page.find(:css, '.js-toggle-cluster').click
        fill_in 'cluster_name', with: 'dev-cluster'
        click_button 'Save'
      end

      it 'user sees the successful message' do
        expect(page).to have_content('Cluster was successfully updated.')
      end
    end

    context 'when user changes cluster name' do
      before do
        fill_in 'cluster_name', with: 'my-dev-cluster'
        click_button 'Save'
      end

      it 'user sees the successful message' do
        expect(page).to have_content('Cluster was successfully updated.')
        expect(cluster.reload.cluster_name).to eq('my-dev-cluster')
      end
    end

    context 'when user destroy the cluster' do
      before do
        page.accept_confirm do
          click_link 'Remove integration'
        end
      end

      it 'user sees creation form with the successful message' do
        expect(page).to have_content('Cluster integration was successfully removed.')
        expect(page).to have_link('Create on GKE')
      end
    end
  end
end
