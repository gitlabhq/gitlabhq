# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Gcp Cluster', :js, feature_category: :deployment_management do
  include GoogleApi::CloudPlatformHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    gitlab_sign_in(user)
    allow(Projects::ClustersController).to receive(:STATUS_POLLING_INTERVAL) { 100 }
  end

  context 'when user has signed with Google' do
    let(:project_id) { 'test-project-1234' }

    before do
      allow_any_instance_of(Projects::ClustersController)
        .to receive(:token_in_session).and_return('token')
      allow_any_instance_of(Projects::ClustersController)
        .to receive(:expires_at_in_session).and_return(1.hour.since.to_i.to_s)
    end

    context 'when user have a cluster and visits cluster page' do
      let(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

      before do
        visit project_cluster_path(project, cluster)
      end

      it 'user sees a cluster details page' do
        expect(page).to have_button('Save changes')
        expect(page.find(:css, '.cluster-name').value).to eq(cluster.name)
      end

      include_examples "user disables a cluster"

      context 'when user changes cluster parameters' do
        before do
          fill_in 'cluster_platform_kubernetes_attributes_namespace', with: 'my-namespace'
          page.within('.js-provider-details') { click_button 'Save changes' }
        end

        it 'user sees the successful message' do
          expect(page).to have_content('Kubernetes cluster was successfully updated.')
          expect(cluster.reload.platform_kubernetes.namespace).to eq('my-namespace')
        end
      end

      context 'when a user adds an existing cluster' do
        before do
          visit project_clusters_path(project)

          click_button(class: 'gl-new-dropdown-toggle', text: 'Connect a cluster (agent)')
          click_link 'Connect a cluster (certificate - deprecated)'
        end

        it 'user sees the "Environment scope" field' do
          expect(page).to have_css('#cluster_environment_scope')
        end
      end

      context 'when user destroys the cluster' do
        before do
          click_link 'Advanced Settings'
          find_by_testid('remove-integration-button').click
          fill_in 'confirm_cluster_name_input', with: cluster.name
          find_by_testid('remove-integration-modal-button').click
          click_link 'Certificate'
        end

        it 'user sees creation form with the successful message' do
          expect(page).to have_content('Kubernetes cluster integration was successfully removed.')
        end
      end
    end
  end

  context 'when user has not dismissed GCP signup offer' do
    before do
      visit project_clusters_path(project)
    end

    it 'user sees offer on cluster index page' do
      expect(page).to have_css('.gcp-signup-offer')
    end
  end

  context 'when user has dismissed GCP signup offer' do
    before do
      visit project_clusters_path(project)
      click_link 'Certificate'
    end

    it 'user does not see offer after dismissing' do
      expect(page).to have_css('.gcp-signup-offer')

      find('.gcp-signup-offer .js-close').click
      wait_for_requests

      expect(page).not_to have_css('.gcp-signup-offer')
    end
  end

  context 'when third party offers are disabled', :clean_gitlab_redis_shared_state do
    let(:user) { create(:admin) }

    before do
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      enable_admin_mode!(user)
      visit general_admin_application_settings_path
    end

    it 'user does not see the offer' do
      within_testid('third-party-offers-settings') do
        click_button 'Expand'
        check 'Do not display content for customer experience improvement and offers from third parties'
        click_button 'Save changes'
      end

      expect(page).to have_content "Application settings saved successfully"

      visit project_clusters_path(project)

      expect(page).not_to have_css('.gcp-signup-offer')
    end
  end
end
