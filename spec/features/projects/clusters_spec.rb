# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Clusters', :js, feature_category: :environment_management do
  include GoogleApi::CloudPlatformHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when user does not have a cluster and visits cluster index page' do
    before do
      visit project_clusters_path(project)
      click_link 'Certificate'
    end

    it 'sees empty state' do
      expect(page).to have_selector('[data-testid="clusters-empty-state"]')
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

      context 'when user filled form with environment scope' do
        before do
          visit_connect_cluster_page

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
          visit_connect_cluster_page

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
  end

  context 'when user has a cluster and visits cluster index page' do
    let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }

    before do
      visit project_clusters_path(project)
      click_link 'Certificate'
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
      visit_create_cluster_page
    end

    it 'user sees a link to create a GKE cluster' do
      expect(page).to have_link('Google GKE')
    end

    it 'user sees a link to create an EKS cluster' do
      expect(page).to have_link('Amazon EKS')
    end
  end

  def visit_create_cluster_page
    visit project_clusters_path(project)

    click_button(class: 'gl-new-dropdown-toggle', text: 'Connect a cluster (agent)')
    click_link 'Create a cluster'
  end

  def visit_connect_cluster_page
    click_button(class: 'gl-new-dropdown-toggle', text: 'Connect a cluster (agent)')
    click_link 'Connect a cluster (certificate - deprecated)'
  end
end
