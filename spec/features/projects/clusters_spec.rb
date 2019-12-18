# frozen_string_literal: true

require 'spec_helper'

describe 'Clusters', :js do
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
      expect(page).to have_link('Add Kubernetes cluster')
      expect(page).to have_selector('.empty-state')
    end
  end

  context 'when user has a cluster and visits cluster index page' do
    let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }

    before do
      visit project_clusters_path(project)
    end

    it 'user sees a table with one cluster' do
      # One is the header row, the other the cluster row
      expect(page).to have_selector('.gl-responsive-table-row', count: 2)
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

      click_link 'Add Kubernetes cluster'
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
