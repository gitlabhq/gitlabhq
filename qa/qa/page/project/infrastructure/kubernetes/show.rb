# frozen_string_literal: true

module QA
  module Page
    module Project
      module Infrastructure
        module Kubernetes
          class Show < Page::Base
            view 'app/assets/javascripts/clusters/forms/components/integration_form.vue' do
              element :integration_status_toggle, required: true
              element :base_domain_field, required: true
              element :save_changes_button, required: true
            end

            view 'app/views/clusters/clusters/_details_tab.html.haml' do
              element :details, required: true
            end

            view 'app/views/clusters/clusters/_health.html.haml' do
              element :cluster_health_section
            end

            view 'app/views/clusters/clusters/_health_tab.html.haml' do
              element :health, required: true
            end

            def open_details
              has_element?(:details, wait: 30)
              click_element :details
            end

            def set_domain(domain)
              fill_element :base_domain_field, domain
            end

            def save_domain
              click_element :save_changes_button, Page::Project::Infrastructure::Kubernetes::Show
            end

            def wait_for_cluster_health
              wait_until(max_duration: 120, sleep_interval: 3, reload: true) do
                has_cluster_health_graphs?
              end
            end

            def open_health
              has_element?(:health, wait: 30)
              click_element :health
            end

            def has_cluster_health_graphs?
              within_cluster_health_section do
                has_text?('CPU Usage')
              end
            end

            def within_cluster_health_section
              within_element :cluster_health_section do
                yield
              end
            end
          end
        end
      end
    end
  end
end
