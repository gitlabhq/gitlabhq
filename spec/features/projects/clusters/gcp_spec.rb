# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Gcp Cluster', :js do
  include GoogleApi::CloudPlatformHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    gitlab_sign_in(user)
    allow(Projects::ClustersController).to receive(:STATUS_POLLING_INTERVAL) { 100 }
  end

  def submit_form
    execute_script('document.querySelector(".js-gke-cluster-creation-submit").removeAttribute("disabled")')
    execute_script('document.querySelector(".js-gke-cluster-creation-submit").click()')
  end

  context 'when user has signed with Google' do
    let(:project_id) { 'test-project-1234' }

    before do
      allow_any_instance_of(Projects::ClustersController)
        .to receive(:token_in_session).and_return('token')
      allow_any_instance_of(Projects::ClustersController)
        .to receive(:expires_at_in_session).and_return(1.hour.since.to_i.to_s)
    end

    context 'when user does not have a cluster and visits cluster index page' do
      before do
        visit project_clusters_path(project)

        click_link 'Integrate with a cluster certificate'
        click_link 'Create new cluster'
        click_link 'Google GKE'
      end

      it 'highlights Google GKE logo' do
        expect(page).to have_css('.js-create-gcp-cluster-button.active')
      end

      context 'when user filled form with valid parameters' do
        subject { submit_form }

        before do
          allow_any_instance_of(GoogleApi::CloudPlatform::Client)
            .to receive(:projects_zones_clusters_create) do
            OpenStruct.new(
              self_link: 'projects/gcp-project-12345/zones/us-central1-a/operations/ope-123',
              status: 'RUNNING'
            )
          end

          allow(WaitForClusterCreationWorker).to receive(:perform_in).and_return(nil)

          expect(page).to have_css('.js-gcp-project-id-dropdown')

          execute_script('document.querySelector(".js-gcp-project-id-dropdown input").setAttribute("type", "text")')
          execute_script('document.querySelector(".js-gcp-zone-dropdown input").setAttribute("type", "text")')
          execute_script('document.querySelector(".js-gcp-machine-type-dropdown input").setAttribute("type", "text")')

          fill_in 'cluster[name]', with: 'dev-cluster'
          fill_in 'cluster[provider_gcp_attributes][gcp_project_id]', with: 'gcp-project-123'
          fill_in 'cluster[provider_gcp_attributes][zone]', with: 'us-central1-a'
          fill_in 'cluster[provider_gcp_attributes][machine_type]', with: 'n1-standard-2'
        end

        it 'users sees a form with the GCP token' do
          expect(page).to have_selector(:css, 'form[data-token="token"]')
        end

        it 'user sees a cluster details page and creation status' do
          subject

          expect(page).to have_content('Kubernetes cluster is being created...')

          Clusters::Cluster.last.provider.make_created!

          expect(page).to have_content('Kubernetes cluster was successfully created')
        end

        it 'user sees a error if something wrong during creation' do
          subject

          expect(page).to have_content('Kubernetes cluster is being created...')

          Clusters::Cluster.last.provider.make_errored!('Something wrong!')

          expect(page).to have_content('Something wrong!')
        end
      end

      context 'when user filled form with invalid parameters' do
        before do
          submit_form
        end

        it 'user sees a validation error' do
          expect(page).to have_css('.gl-field-error')
        end
      end
    end

    context 'when user does have a cluster and visits cluster page' do
      let(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

      before do
        visit project_cluster_path(project, cluster)
      end

      it 'user sees a cluster details page' do
        expect(page).to have_button('Save changes')
        expect(page.find(:css, '.cluster-name').value).to eq(cluster.name)
      end

      context 'when user disables the cluster' do
        before do
          page.find(:css, '.js-cluster-enable-toggle-area .js-project-feature-toggle').click
          page.within('.js-cluster-details-form') { click_button 'Save changes' }
        end

        it 'user sees the successful message' do
          expect(page).to have_content('Kubernetes cluster was successfully updated.')
        end
      end

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

          click_link 'Connect cluster with certificate'
          click_link 'Connect existing cluster'
        end

        it 'user sees the "Environment scope" field' do
          expect(page).to have_css('#cluster_environment_scope')
        end
      end

      context 'when user destroys the cluster' do
        before do
          click_link 'Advanced Settings'
          click_button 'Remove integration and resources'
          fill_in 'confirm_cluster_name_input', with: cluster.name
          click_button 'Remove integration'
        end

        it 'user sees creation form with the successful message' do
          expect(page).to have_content('Kubernetes cluster integration was successfully removed.')
          expect(page).to have_link('Integrate with a cluster certificate')
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

    it 'user sees offer on cluster create page' do
      click_link 'Integrate with a cluster certificate'

      expect(page).to have_css('.gcp-signup-offer')
    end
  end

  context 'when user has dismissed GCP signup offer' do
    before do
      visit project_clusters_path(project)
    end

    it 'user does not see offer after dismissing' do
      expect(page).to have_css('.gcp-signup-offer')

      find('.gcp-signup-offer .js-close').click
      wait_for_requests

      click_link 'Integrate with a cluster certificate'

      expect(page).not_to have_css('.gcp-signup-offer')
    end
  end

  context 'when third party offers are disabled', :clean_gitlab_redis_shared_state do
    let(:admin) { create(:admin) }

    before do
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      sign_in(admin)
      gitlab_enable_admin_mode_sign_in(admin)
      visit general_admin_application_settings_path
    end

    it 'user does not see the offer' do
      page.within('.as-third-party-offers') do
        click_button 'Expand'
        check 'Do not display offers from third parties'
        click_button 'Save changes'
      end

      expect(page).to have_content "Application settings saved successfully"

      visit project_clusters_path(project)

      expect(page).not_to have_css('.gcp-signup-offer')
    end
  end
end
