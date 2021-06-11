# frozen_string_literal: true

module QA
  module Page
    module Project
      module Infrastructure
        module Kubernetes
          class AddExisting < Page::Base
            view 'app/views/clusters/clusters/user/_form.html.haml' do
              element :cluster_name, 'text_field :name' # rubocop:disable QA/ElementWithPattern
              element :api_url, 'url_field :api_url' # rubocop:disable QA/ElementWithPattern
              element :ca_certificate, 'text_area :ca_cert' # rubocop:disable QA/ElementWithPattern
              element :token, 'text_field :token' # rubocop:disable QA/ElementWithPattern
              element :add_kubernetes_cluster_button
              element :rbac_checkbox
            end

            def set_cluster_name(name)
              fill_in 'cluster_name', with: name
            end

            def set_api_url(api_url)
              fill_in 'cluster_platform_kubernetes_attributes_api_url', with: QA::Runtime::Env.cluster_api_url || api_url
            end

            def set_ca_certificate(ca_certificate)
              fill_in 'cluster_platform_kubernetes_attributes_ca_cert', with: ca_certificate
            end

            def set_token(token)
              fill_in 'cluster_platform_kubernetes_attributes_token', with: token
            end

            def add_cluster!
              click_element :add_kubernetes_cluster_button, Page::Project::Infrastructure::Kubernetes::Show
            end

            def uncheck_rbac!
              uncheck_element(:rbac_checkbox)
            end
          end
        end
      end
    end
  end
end
