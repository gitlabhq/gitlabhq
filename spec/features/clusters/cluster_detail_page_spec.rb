# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Clusterable > Show page' do
  include KubernetesHelpers

  let(:current_user) { create(:user) }
  let(:cluster_ingress_help_text_selector) { '.js-ingress-domain-help-text' }
  let(:hide_modifier_selector) { '.hide' }

  before do
    sign_in(current_user)
  end

  shared_examples 'show page' do
    it 'displays cluster type label' do
      visit cluster_path

      expect(page).to have_content(cluster_type_label)
    end

    it 'allow the user to set domain', :js do
      visit cluster_path

      within '.js-cluster-details-form' do
        fill_in('cluster_base_domain', with: 'test.com')
        click_on 'Save changes'
      end

      expect(page).to have_content('Kubernetes cluster was successfully updated.')
    end

    it 'does not show the environments tab' do
      visit cluster_path

      expect(page).not_to have_selector('.js-cluster-nav-environments', text: 'Environments')
    end
  end

  shared_examples 'editing a GCP cluster' do
    before do
      visit cluster_path
    end

    it 'is not able to edit the name, API url, CA certificate nor token' do
      within('.js-provider-details') do
        cluster_name_field = find('.cluster-name')
        api_url_field = find('#cluster_platform_kubernetes_attributes_api_url')
        ca_certificate_field = find('#cluster_platform_kubernetes_attributes_ca_cert')
        token_field = find('#cluster_platform_kubernetes_attributes_token')

        expect(cluster_name_field).to be_readonly
        expect(api_url_field).to be_readonly
        expect(ca_certificate_field).to be_readonly
        expect(token_field).to be_readonly
      end
    end

    it 'displays GKE information' do
      click_link 'Advanced Settings'

      within('#advanced-settings-section') do
        expect(page).to have_content('Google Kubernetes Engine')
        expect(page).to have_content('Manage your Kubernetes cluster by visiting')
        expect_common_advanced_options
      end
    end
  end

  shared_examples 'editing a user-provided cluster' do
    before do
      stub_kubeclient_discover(cluster.platform.api_url)
      visit cluster_path
    end

    it 'is able to edit the name, API url, CA certificate and token' do
      within('.js-provider-details') do
        cluster_name_field = find('#cluster_name')
        api_url_field = find('#cluster_platform_kubernetes_attributes_api_url')
        ca_certificate_field = find('#cluster_platform_kubernetes_attributes_ca_cert')
        token_field = find('#cluster_platform_kubernetes_attributes_token')

        expect(cluster_name_field).not_to be_readonly
        expect(api_url_field).not_to be_readonly
        expect(ca_certificate_field).not_to be_readonly
        expect(token_field).not_to be_readonly
      end
    end

    it 'does not display GKE information' do
      click_link 'Advanced Settings'

      within('#advanced-settings-section') do
        expect(page).not_to have_content('Google Kubernetes Engine')
        expect(page).not_to have_content('Manage your Kubernetes cluster by visiting')
        expect_common_advanced_options
      end
    end
  end

  context 'when clusterable is a project' do
    let(:clusterable) { create(:project) }
    let(:cluster_path) { project_cluster_path(clusterable, cluster) }
    let(:cluster) { create(:cluster, :provided_by_gcp, :project, projects: [clusterable]) }

    before do
      clusterable.add_maintainer(current_user)
    end

    it_behaves_like 'show page' do
      let(:cluster_type_label) { 'Project cluster' }
    end

    it_behaves_like 'editing a GCP cluster'

    it_behaves_like 'editing a user-provided cluster' do
      let(:cluster) { create(:cluster, :provided_by_user, :project, projects: [clusterable]) }
    end
  end

  context 'when clusterable is a group' do
    let(:clusterable) { create(:group) }
    let(:cluster_path) { group_cluster_path(clusterable, cluster) }
    let(:cluster) { create(:cluster, :provided_by_gcp, :group, groups: [clusterable]) }

    before do
      clusterable.add_maintainer(current_user)
    end

    it_behaves_like 'show page' do
      let(:cluster_type_label) { 'Group cluster' }
    end

    it_behaves_like 'editing a GCP cluster'

    it_behaves_like 'editing a user-provided cluster' do
      let(:cluster) { create(:cluster, :provided_by_user, :group, groups: [clusterable]) }
    end
  end

  context 'when clusterable is an instance' do
    let(:current_user) { create(:admin) }
    let(:cluster_path) { admin_cluster_path(cluster) }
    let(:cluster) { create(:cluster, :provided_by_gcp, :instance) }

    before do
      gitlab_enable_admin_mode_sign_in(current_user)
    end

    it_behaves_like 'show page' do
      let(:cluster_type_label) { 'Instance cluster' }
    end

    it_behaves_like 'editing a GCP cluster'

    it_behaves_like 'editing a user-provided cluster' do
      let(:cluster) { create(:cluster, :provided_by_user, :instance) }
    end
  end

  private

  def expect_common_advanced_options
    aggregate_failures do
      expect(page).to have_content('Cluster management project')
      expect(page).to have_content('Clear cluster cache')
      expect(page).to have_content('Remove Kubernetes cluster integration')
    end
  end
end
