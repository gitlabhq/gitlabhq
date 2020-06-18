# frozen_string_literal: true

module QA
  module Page
    module Project
      class NewExperiment < Page::Base
        view 'app/assets/javascripts/projects/experiment_new_project_creation/components/welcome.vue' do
          element :blank_project_link, ':data-qa-selector="`${panel.name}_link`"' # rubocop:disable QA/ElementWithPattern
          element :create_from_template_link, ':data-qa-selector="`${panel.name}_link`"' # rubocop:disable QA/ElementWithPattern
        end

        def shown?
          has_element? :blank_project_link
        end

        def click_blank_project_link
          click_element :blank_project_link
        end

        def click_create_from_template_link
          click_element :create_from_template_link
        end
      end
    end
  end
end
