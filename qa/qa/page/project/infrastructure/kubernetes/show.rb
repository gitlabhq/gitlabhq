# frozen_string_literal: true

module QA
  module Page
    module Project
      module Infrastructure
        module Kubernetes
          class Show < Page::Base
            view 'app/assets/javascripts/clusters/forms/components/integration_form.vue' do
              element :integration_status_toggle
              element :base_domain_field
            end

            view 'app/assets/javascripts/integrations/edit/components/integration_form_actions.vue' do
              element :save_changes_button
            end

            def set_domain(domain)
              fill_element :base_domain_field, domain
            end

            def save_domain
              click_element :save_changes_button, Page::Project::Infrastructure::Kubernetes::Show
            end
          end
        end
      end
    end
  end
end
