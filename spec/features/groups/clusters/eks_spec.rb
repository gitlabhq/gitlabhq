# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group AWS EKS Cluster', :js do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    group.add_maintainer(user)
    gitlab_sign_in(user)

    allow(Groups::ClustersController).to receive(:STATUS_POLLING_INTERVAL) { 100 }
    allow_any_instance_of(Clusters::Kubernetes::CreateOrUpdateNamespaceService).to receive(:execute)
    allow_any_instance_of(Clusters::Cluster).to receive(:retrieve_connection_status).and_return(:connected)
    stub_application_setting(eks_integration_enabled: true)
  end

  context 'when user does not have a cluster and visits group clusters page' do
    before do
      visit group_clusters_path(group)

      click_button(class: 'dropdown-toggle-split')
      click_link 'Create a cluster (deprecated)'
    end

    context 'when user creates a cluster on AWS EKS' do
      before do
        click_link 'Amazon EKS'
      end

      it 'user sees a form to create an EKS cluster' do
        expect(page).to have_content('Authenticate with Amazon Web Services')
      end
    end
  end
end
