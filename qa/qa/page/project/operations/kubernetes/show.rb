module QA
  module Page
    module Project
      module Operations
        module Kubernetes
          class Show < Page::Base
            view 'app/assets/javascripts/clusters/components/application_row.vue' do
              element :application_row, 'js-cluster-application-row-${this.id}'
              element :install_button, "s__('ClusterIntegration|Install')"
              element :installed_button, "s__('ClusterIntegration|Installed')"
            end

            view 'app/assets/javascripts/clusters/components/applications.vue' do
              element :ingress_ip_address, 'id="ingress-ip-address"'
            end

            def install!(application_name)
              within(".js-cluster-application-row-#{application_name}") do
                page.has_button?('Install', wait: 30)
                click_on 'Install'
              end
            end

            def await_installed(application_name)
              within(".js-cluster-application-row-#{application_name}") do
                page.has_text?('Installed', wait: 300)
              end
            end

            def ingress_ip
              # We need to wait longer since it can take some time before the
              # ip address is assigned for the ingress controller
              page.find('#ingress-ip-address', wait: 500).value
            end
          end
        end
      end
    end
  end
end
