# frozen_string_literal: true

require 'spec_helper'

describe 'AWS EKS Cluster', :js do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    gitlab_sign_in(user)
    allow(Projects::ClustersController).to receive(:STATUS_POLLING_INTERVAL) { 100 }
    stub_application_setting(eks_integration_enabled: true)
  end

  context 'when user does not have a cluster and visits cluster index page' do
    let(:project_id) { 'test-project-1234' }

    before do
      visit project_clusters_path(project)

      click_link 'Add Kubernetes cluster'
    end

    context 'when user creates a cluster on AWS EKS' do
      before do
        click_link 'Amazon EKS'
      end

      it 'user sees a form to create an EKS cluster' do
        expect(page).to have_content('Create new cluster on EKS')
      end
    end
  end
end
