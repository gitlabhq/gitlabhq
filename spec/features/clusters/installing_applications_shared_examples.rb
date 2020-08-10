# frozen_string_literal: true

RSpec.shared_examples "installing applications for a cluster" do
  before do
    # Reduce interval from 10 seconds which is too long for an automated test
    stub_const("#{Clusters::ClustersController}::STATUS_POLLING_INTERVAL", 500)

    visit cluster_path
  end

  context 'when cluster is being created' do
    let(:cluster) { create(:cluster, :providing_by_gcp, *cluster_factory_args) }

    it 'user is unable to install applications' do
      expect(page).not_to have_text('Helm')
      expect(page).not_to have_text('Install')
    end
  end

  context 'when cluster is created' do
    let(:cluster) { create(:cluster, :provided_by_gcp, *cluster_factory_args) }

    before do
      page.within('.js-edit-cluster-form') do
        click_link 'Applications'
      end
    end

    it 'user can install applications' do
      wait_for_requests

      application_row = '.js-cluster-application-row-ingress'

      page.within(application_row) do
        expect(page).not_to have_css('.js-cluster-application-install-button[disabled]')
        expect(page).to have_css('.js-cluster-application-install-button', exact_text: 'Install')
      end
    end

    it 'does not show the Helm application' do
      expect(page).not_to have_selector(:css, '.js-cluster-application-row-helm')
    end

    context 'when user installs Knative' do
      context 'on an abac cluster' do
        let(:cluster) { create(:cluster, :provided_by_gcp, :rbac_disabled, *cluster_factory_args) }

        it 'shows info block and not be installable' do
          page.within('.js-cluster-application-row-knative') do
            expect(page).to have_css('.rbac-notice')
            expect(page.find(:css, '.js-cluster-application-install-button')['disabled']).to eq('true')
          end
        end
      end

      context 'on an rbac cluster' do
        let(:cluster) { create(:cluster, :provided_by_gcp, *cluster_factory_args) }

        it 'does not show callout block and be installable' do
          page.within('.js-cluster-application-row-knative') do
            expect(page).not_to have_css('p', text: 'You must have an RBAC-enabled cluster', visible: :all)
            expect(page).to have_css('.js-cluster-application-install-button:not([disabled])')
          end
        end

        describe 'when user clicks install button' do
          before do
            allow(ClusterInstallAppWorker).to receive(:perform_async)
            allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_in)
            allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_async)

            page.within('.js-cluster-application-row-knative') do
              expect(page).to have_css('.js-cluster-application-install-button:not([disabled])')

              page.find('.js-knative-domainname').set("domain.example.org")

              click_button 'Install'

              wait_for_requests

              expect(page).to have_css('.js-cluster-application-install-button', exact_text: 'Installing')

              Clusters::Cluster.last.application_knative.make_installing!
              Clusters::Cluster.last.application_knative.make_installed!
              Clusters::Cluster.last.application_knative.update_attribute(:external_ip, '127.0.0.1')
            end
          end

          it 'shows status transition' do
            page.within('.js-cluster-application-row-knative') do
              expect(page).to have_field('Knative Domain Name:', with: 'domain.example.org')
              expect(page).to have_css('.js-cluster-application-uninstall-button', exact_text: 'Uninstall')
            end

            expect(page).to have_content('Knative was successfully installed on your Kubernetes cluster')
            expect(page).to have_css('.js-knative-save-domain-button'), exact_text: 'Save changes'
          end

          it 'can then update the domain' do
            page.within('.js-cluster-application-row-knative') do
              expect(ClusterPatchAppWorker).to receive(:perform_async)

              expect(page).to have_field('Knative Domain Name:', with: 'domain.example.org')

              page.find('.js-knative-domainname').set("new.domain.example.org")

              click_button 'Save changes'

              wait_for_requests

              expect(page).to have_field('Knative Domain Name:', with: 'new.domain.example.org')
            end
          end
        end
      end
    end

    context 'when user installs Cert Manager' do
      before do
        allow(ClusterInstallAppWorker).to receive(:perform_async)
        allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_in)
        allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_async)
      end

      it 'shows status transition' do
        page.within('.js-cluster-application-row-cert_manager') do
          click_button 'Install'
          wait_for_requests

          expect(page).to have_field('Issuer Email', with: cluster.user.email)
          expect(page).to have_css('.js-cluster-application-install-button', exact_text: 'Installing')

          Clusters::Cluster.last.application_cert_manager.make_installing!

          expect(page).to have_field('Issuer Email', with: cluster.user.email)
          expect(page).to have_css('.js-cluster-application-install-button', exact_text: 'Installing')

          Clusters::Cluster.last.application_cert_manager.make_installed!

          expect(page).to have_field('Issuer Email', with: cluster.user.email)
          expect(page).to have_css('.js-cluster-application-uninstall-button', exact_text: 'Uninstall')
        end

        expect(page).to have_content('Cert-Manager was successfully installed on your Kubernetes cluster')
      end

      it 'installs with custom email' do
        custom_email = 'new_email@example.org'

        page.within('.js-cluster-application-row-cert_manager') do
          # Wait for the polling to finish
          wait_for_requests

          page.find('.js-email').set(custom_email)
          click_button 'Install'
          wait_for_requests

          expect(page).to have_field('Issuer Email', with: custom_email)
          expect(page).to have_css('.js-cluster-application-install-button', exact_text: 'Installing')

          Clusters::Cluster.last.application_cert_manager.make_installing!

          expect(page).to have_field('Issuer Email', with: custom_email)
          expect(page).to have_css('.js-cluster-application-install-button', exact_text: 'Installing')

          Clusters::Cluster.last.application_cert_manager.make_installed!

          expect(page).to have_field('Issuer Email', with: custom_email)
          expect(page).to have_css('.js-cluster-application-uninstall-button', exact_text: 'Uninstall')
        end
      end
    end

    context 'when user installs Elastic Stack' do
      before do
        allow(ClusterInstallAppWorker).to receive(:perform_async)

        page.within('.js-cluster-application-row-elastic_stack') do
          click_button 'Install'
        end

        wait_for_requests
      end

      it 'shows status transition' do
        page.within('.js-cluster-application-row-elastic_stack') do
          expect(page).to have_css('.js-cluster-application-install-button', exact_text: 'Installing')

          Clusters::Cluster.last.application_elastic_stack.make_installing!

          expect(page).to have_css('.js-cluster-application-install-button', exact_text: 'Installing')

          Clusters::Cluster.last.application_elastic_stack.make_installed!

          expect(page).to have_css('.js-cluster-application-uninstall-button', exact_text: 'Uninstall')
        end

        expect(page).to have_content('Elastic Stack was successfully installed on your Kubernetes cluster')
      end
    end

    context 'when user installs Ingress' do
      before do
        allow(ClusterInstallAppWorker).to receive(:perform_async)
        allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_in)
        allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_async)

        page.within('.js-cluster-application-row-ingress') do
          expect(page).to have_css('.js-cluster-application-install-button:not([disabled])')
          page.find(:css, '.js-cluster-application-install-button').click

          wait_for_requests
        end
      end

      it 'shows the status transition' do
        page.within('.js-cluster-application-row-ingress') do
          # FE sends request and gets the response, then the buttons is "Installing"
          expect(page).to have_css('.js-cluster-application-install-button[disabled]', exact_text: 'Installing')

          Clusters::Cluster.last.application_ingress.make_installing!

          # FE starts polling and update the buttons to "Installing"
          expect(page).to have_css('.js-cluster-application-install-button[disabled]', exact_text: 'Installing')

          # The application becomes installed but we keep waiting for external IP address
          Clusters::Cluster.last.application_ingress.make_installed!

          expect(page).to have_css('.js-cluster-application-install-button[disabled]', exact_text: 'Installed')
          expect(page).to have_selector('.js-no-endpoint-message')
          expect(page).to have_selector('.js-ingress-ip-loading-icon')

          # We receive the external IP address and display
          Clusters::Cluster.last.application_ingress.update!(external_ip: '192.168.1.100')

          expect(page).not_to have_css('button', exact_text: 'Install', visible: :all)
          expect(page).not_to have_css('button', exact_text: 'Installing', visible: :all)
          expect(page).to have_css('.js-cluster-application-uninstall-button:not([disabled])', exact_text: 'Uninstall')
          expect(page).not_to have_css('p', text: 'The endpoint is in the process of being assigned', visible: :all)
          expect(page.find('.js-endpoint').value).to eq('192.168.1.100')
        end

        expect(page).to have_content('Ingress was successfully installed on your Kubernetes cluster')
      end
    end
  end
end

RSpec.shared_examples "installing applications on a cluster" do
  it_behaves_like "installing applications for a cluster", false
  it_behaves_like "installing applications for a cluster", true
end
