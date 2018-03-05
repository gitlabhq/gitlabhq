module QA
  feature 'Kubernetes Applications', :core, :docker do
    after do
      # Destroy @created_cluster
    end

    scenario 'user deploys helm applications to kubernetes cluster' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      @created_cluster = Factory::Resource::Cluster.fabricate! do |cluster|
      end

      expect(page).to have_css('h4', text: 'Applications')

      #expect(page).to_not have_css('.js-cluster-application-row-helm .js-cluster-application-install-button[disabled]')
      #Page::Project::Clusters::Show.act { install_helm_tiller }
      #expect(page).to have_css('.js-cluster-application-row-helm .js-cluster-application-install-button[disabled]')
      #expect(page).to have_css('.js-cluster-application-row-helm .js-cluster-application-install-button', text: 'Installed')
      #expect(page).to_not have_css('.js-cluster-application-row-ingress .js-cluster-application-install-button[disabled]')
      #Page::Project::Clusters::Show.act { install_ingress }
      #expect(page).to have_css('.js-cluster-application-row-ingress .js-cluster-application-install-button[disabled]')
      #expect(page).to have_css('.js-cluster-application-row-ingress .js-cluster-application-install-button', text: 'Installed')

      #expect(page).to have_content('Ingress IP Address')

      # Assert there is an HTTP server on the end of this IP address
    end
  end
end
