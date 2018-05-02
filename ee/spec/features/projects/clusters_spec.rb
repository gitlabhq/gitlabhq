require 'spec_helper'

feature 'EE Clusters' do
  include GoogleApi::CloudPlatformHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    gitlab_sign_in(user)
  end

  context 'when user has a cluster' do
    context 'when license has multiple clusters feature' do
      before do
        allow(License).to receive(:feature_available?).and_call_original
        allow(License).to receive(:feature_available?).with(:multiple_clusters).and_return(true)
      end

      context 'when user adds an existing cluster' do
        before do
          create(:cluster, :provided_by_user, name: 'default-cluster', environment_scope: '*', projects: [project])
          visit project_clusters_path(project)
        end

        it 'user sees a add cluster button ' do
          expect(page).not_to have_selector('.js-add-cluster.readonly')
          expect(page).to have_selector('.js-add-cluster')
        end

        context 'when user filled form with environment scope' do
          before do
            click_link 'Add Kubernetes cluster'
            click_link 'Add an existing Kubernetes cluster'
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
            within '.cluster_integration_form' do
              click_button 'Save changes'
            end
          end

          it 'user sees a cluster details page' do
            expect(page.find_field('cluster[environment_scope]').value).to eq('production/*')
          end
        end

        context 'when user updates duplicated environment scope' do
          before do
            click_link 'Add Kubernetes cluster'
            click_link 'Add an existing Kubernetes cluster'
            fill_in 'cluster_name', with: 'staging-cluster'
            fill_in 'cluster_environment_scope', with: '*'
            click_button 'Add Kubernetes cluster'
          end

          it 'users sees an environment scope validation error' do
            expect(page).to have_content('cannot add duplicated environment scope')
          end
        end
      end

      context 'when user adds an Google Kubernetes Engine cluster' do
        before do
          allow_any_instance_of(Projects::Clusters::GcpController)
            .to receive(:token_in_session).and_return('token')
          allow_any_instance_of(Projects::Clusters::GcpController)
            .to receive(:expires_at_in_session).and_return(1.hour.since.to_i.to_s)

          allow_any_instance_of(Projects::Clusters::GcpController).to receive(:authorize_google_project_billing)
          allow_any_instance_of(Projects::Clusters::GcpController).to receive(:google_project_billing_status).and_return(true)

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

        it 'user sees a add cluster button ' do
          expect(page).not_to have_selector('.js-add-cluster.readonly')
          expect(page).to have_selector('.js-add-cluster')
        end

        context 'when user filled form with environment scope' do
          before do
            click_link 'Add Kubernetes cluster'
            click_link 'Create on Google Kubernetes Engine'
            fill_in 'cluster_provider_gcp_attributes_gcp_project_id', with: 'gcp-project-123'
            fill_in 'cluster_name', with: 'staging-cluster'
            fill_in 'cluster_environment_scope', with: 'staging/*'
            click_button 'Create Kubernetes cluster'
          end

          it 'user sees a cluster details page' do
            expect(page).to have_content('Kubernetes cluster integration is enabled for this project')
            expect(page.find_field('cluster[environment_scope]').value).to eq('staging/*')
          end
        end

        context 'when user updates environment scope' do
          before do
            click_link 'default-cluster'
            fill_in 'cluster_environment_scope', with: 'production/*'
            within ".cluster_integration_form" do
              click_button 'Save changes'
            end
          end

          it 'user sees a cluster details page' do
            expect(page.find_field('cluster[environment_scope]').value).to eq('production/*')
          end
        end

        context 'when user updates duplicated environment scope' do
          before do
            click_link 'Add Kubernetes cluster'
            click_link 'Create on Google Kubernetes Engine'
            fill_in 'cluster_provider_gcp_attributes_gcp_project_id', with: 'gcp-project-123'
            fill_in 'cluster_name', with: 'staging-cluster'
            fill_in 'cluster_environment_scope', with: '*'
            click_button 'Create Kubernetes cluster'
          end

          it 'users sees an environment scope validation error' do
            expect(page).to have_content('cannot add duplicated environment scope')
          end
        end
      end
    end

    context 'when license does not have multiple clusters feature' do
      before do
        allow(License).to receive(:feature_available?).and_call_original
        allow(License).to receive(:feature_available?).with(:multiple_clusters).and_return(false)
        create(:cluster, :provided_by_user, name: 'default-cluster', environment_scope: '*', projects: [project])
      end

      context 'when user visits cluster index page' do
        before do
          visit project_clusters_path(project)
        end

        it 'user sees a disabled add cluster button ' do
          expect(page).to have_selector('.js-add-cluster.disabled')
        end
      end
    end
  end
end
