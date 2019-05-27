# frozen_string_literal: true

require 'spec_helper'

describe 'Clusterable > Show page' do
  include KubernetesHelpers

  let(:current_user) { create(:user) }
  let(:cluster_ingress_help_text_selector) { '.js-ingress-domain-help-text' }
  let(:hide_modifier_selector) { '.hide' }

  before do
    sign_in(current_user)
  end

  shared_examples 'editing domain' do
    before do
      clusterable.add_maintainer(current_user)
    end

    it 'allow the user to set domain' do
      visit cluster_path

      within '#cluster-integration' do
        fill_in('cluster_base_domain', with: 'test.com')
        click_on 'Save changes'
      end

      expect(page.status_code).to eq(200)
      expect(page).to have_content('Kubernetes cluster was successfully updated.')
    end

    context 'when there is a cluster with ingress and external ip' do
      before do
        cluster.create_application_ingress!(external_ip: '192.168.1.100')

        visit cluster_path
      end

      it 'shows help text with the domain as an alternative to custom domain' do
        within '#cluster-integration' do
          expect(find(cluster_ingress_help_text_selector)).not_to match_css(hide_modifier_selector)
        end
      end
    end

    context 'when there is no ingress' do
      it 'alternative to custom domain is not shown' do
        visit cluster_path

        within '#cluster-integration' do
          expect(find(cluster_ingress_help_text_selector)).to match_css(hide_modifier_selector)
        end
      end
    end
  end

  shared_examples 'editing a GCP cluster' do
    before do
      clusterable.add_maintainer(current_user)
      visit cluster_path
    end

    it 'is not able to edit the name, API url, CA certificate nor token' do
      within('#js-cluster-details') do
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
      within('#advanced-settings-section') do
        expect(page).to have_content('Google Kubernetes Engine')
        expect(page).to have_content('Manage your Kubernetes cluster by visiting')
      end
    end
  end

  shared_examples 'editing a user-provided cluster' do
    before do
      stub_kubeclient_discover(cluster.platform.api_url)
      clusterable.add_maintainer(current_user)
      visit cluster_path
    end

    it 'is able to edit the name, API url, CA certificate and token' do
      within('#js-cluster-details') do
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
      within('#advanced-settings-section') do
        expect(page).not_to have_content('Google Kubernetes Engine')
        expect(page).not_to have_content('Manage your Kubernetes cluster by visiting')
      end
    end
  end

  context 'when clusterable is a project' do
    it_behaves_like 'editing domain' do
      let(:clusterable) { create(:project) }
      let(:cluster) { create(:cluster, :provided_by_gcp, :project, projects: [clusterable]) }
      let(:cluster_path) { project_cluster_path(clusterable, cluster) }
    end

    it_behaves_like 'editing a GCP cluster' do
      let(:clusterable) { create(:project) }
      let(:cluster) { create(:cluster, :provided_by_gcp, :project, projects: [clusterable]) }
      let(:cluster_path) { project_cluster_path(clusterable, cluster) }
    end

    it_behaves_like 'editing a user-provided cluster' do
      let(:clusterable) { create(:project) }
      let(:cluster) { create(:cluster, :provided_by_user, :project, projects: [clusterable]) }
      let(:cluster_path) { project_cluster_path(clusterable, cluster) }
    end
  end

  context 'when clusterable is a group' do
    it_behaves_like 'editing domain' do
      let(:clusterable) { create(:group) }
      let(:cluster) { create(:cluster, :provided_by_gcp, :group, groups: [clusterable]) }
      let(:cluster_path) { group_cluster_path(clusterable, cluster) }
    end

    it_behaves_like 'editing a GCP cluster' do
      let(:clusterable) { create(:group) }
      let(:cluster) { create(:cluster, :provided_by_gcp, :group, groups: [clusterable]) }
      let(:cluster_path) { group_cluster_path(clusterable, cluster) }
    end

    it_behaves_like 'editing a user-provided cluster' do
      let(:clusterable) { create(:group) }
      let(:cluster) { create(:cluster, :provided_by_user, :group, groups: [clusterable]) }
      let(:cluster_path) { group_cluster_path(clusterable, cluster) }
    end
  end
end
