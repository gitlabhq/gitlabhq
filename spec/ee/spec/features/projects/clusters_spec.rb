require 'spec_helper'

feature 'EE Clusters' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    gitlab_sign_in(user)
  end

  context 'when user has a cluster' do
    let!(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

    context 'when license has multiple clusters feature' do
      before do
        allow(License).to receive(:feature_available?).and_call_original
        allow(License).to receive(:feature_available?).with(:multiple_clusters).and_return(true)
      end

      context 'when user visits clusters page' do
        before do
          visit project_clusters_path(project)
        end

        it 'user sees a add cluster button ' do
          expect(page).not_to have_selector('.js-add-cluster.disabled')
          expect(page).to have_selector('.js-add-cluster')
        end

        context 'when user tries to create a cluster with a duplicate environment scope' do
          before do
            allow_any_instance_of(Projects::Clusters::GcpController)
              .to receive(:token_in_session).and_return('token')
            allow_any_instance_of(Projects::Clusters::GcpController)
              .to receive(:expires_at_in_session).and_return(1.hour.since.to_i.to_s)
            allow_any_instance_of(GoogleApi::CloudPlatform::Client)
              .to receive(:projects_zones_clusters_create) do
              OpenStruct.new(
                self_link: 'projects/gcp-project-12345/zones/us-central1-a/operations/ope-123',
                status: 'RUNNING'
              )
            end
            allow(WaitForClusterCreationWorker).to receive(:perform_in).and_return(nil)

            click_link 'Add cluster'
            click_link 'Create on GKE'
          end

          it 'users sees an error' do
            fill_in 'cluster_provider_gcp_attributes_gcp_project_id', with: 'gcp-project-123'
            fill_in 'cluster_name', with: 'dev-cluster'
            fill_in 'cluster_environment_scope', with: cluster.environment_scope
            click_button 'Create cluster'
            expect(page).to have_css('#error_explanation')
          end
        end
      end
    end

    context 'when license does not have multiple clusters feature' do
      before do
        allow(License).to receive(:feature_available?).and_call_original
        allow(License).to receive(:feature_available?).with(:multiple_clusters).and_return(false)
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
