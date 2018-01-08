require 'spec_helper'

feature 'Clusters Applications', :js do
  include GoogleApi::CloudPlatformHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  describe 'Installing applications' do
    before do
      visit project_cluster_path(project, cluster)
    end

    context 'when cluster is being created' do
      let(:cluster) { create(:cluster, :providing_by_gcp, projects: [project])}

      scenario 'user is unable to install applications' do
        page.within('.js-cluster-application-row-helm') do
          expect(page.find(:css, '.js-cluster-application-install-button')['disabled']).to eq('true')
          expect(page.find(:css, '.js-cluster-application-install-button').text).to eq('Install')
        end
      end
    end

    context 'when cluster is created' do
      let(:cluster) { create(:cluster, :provided_by_gcp, projects: [project])}

      scenario 'user can install applications' do
        page.within('.js-cluster-application-row-helm') do
          expect(page.find(:css, '.js-cluster-application-install-button')['disabled']).to be_nil
          expect(page.find(:css, '.js-cluster-application-install-button')).to have_content('Install')
        end
      end

      context 'when user installs Helm' do
        before do
          allow(ClusterInstallAppWorker).to receive(:perform_async).and_return(nil)

          page.within('.js-cluster-application-row-helm') do
            page.find(:css, '.js-cluster-application-install-button').click
          end
        end

        it 'he sees status transition' do
          page.within('.js-cluster-application-row-helm') do
            # FE sends request and gets the response, then the buttons is "Install"
            expect(page.find(:css, '.js-cluster-application-install-button')['disabled']).to eq('true')
            expect(page.find(:css, '.js-cluster-application-install-button')).to have_content('Install')

            Clusters::Cluster.last.application_helm.make_installing!

            # FE starts polling and update the buttons to "Installing"
            expect(page.find(:css, '.js-cluster-application-install-button')['disabled']).to eq('true')
            expect(page.find(:css, '.js-cluster-application-install-button')).to have_content('Installing')

            Clusters::Cluster.last.application_helm.make_installed!

            expect(page.find(:css, '.js-cluster-application-install-button')['disabled']).to eq('true')
            expect(page.find(:css, '.js-cluster-application-install-button')).to have_content('Installed')
          end

          expect(page).to have_content('Helm Tiller was successfully installed on your cluster')
        end
      end

      context 'when user installs Ingress' do
        context 'when user installs application: Ingress' do
          before do
            allow(ClusterInstallAppWorker).to receive(:perform_async).and_return(nil)

            create(:clusters_applications_helm, :installed, cluster: cluster)

            page.within('.js-cluster-application-row-ingress') do
              page.find(:css, '.js-cluster-application-install-button').click
            end
          end

          it 'he sees status transition' do
            page.within('.js-cluster-application-row-ingress') do
              # FE sends request and gets the response, then the buttons is "Install"
              expect(page.find(:css, '.js-cluster-application-install-button')['disabled']).to eq('true')
              expect(page.find(:css, '.js-cluster-application-install-button')).to have_content('Install')

              Clusters::Cluster.last.application_ingress.make_installing!

              # FE starts polling and update the buttons to "Installing"
              expect(page.find(:css, '.js-cluster-application-install-button')['disabled']).to eq('true')
              expect(page.find(:css, '.js-cluster-application-install-button')).to have_content('Installing')

              Clusters::Cluster.last.application_ingress.make_installed!

              expect(page.find(:css, '.js-cluster-application-install-button')['disabled']).to eq('true')
              expect(page.find(:css, '.js-cluster-application-install-button')).to have_content('Installed')
            end

            expect(page).to have_content('Ingress was successfully installed on your cluster')
          end
        end
      end
    end
  end
end
