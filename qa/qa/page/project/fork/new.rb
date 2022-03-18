# frozen_string_literal: true

module QA
  module Page
    module Project
      module Fork
        class New < Page::Base
          view 'app/assets/javascripts/pages/projects/forks/new/components/fork_form.vue' do
            element :fork_namespace_dropdown
            element :fork_project_button
            element :fork_privacy_button
          end

          def fork_project(namespace = Runtime::Namespace.path)
            select_element(:fork_namespace_dropdown, namespace)
            click_element(:fork_privacy_button, privacy_level: 'public')
            click_element(:fork_project_button)
          end

          def fork_namespace_dropdown_values
            find_element(:fork_namespace_dropdown).all(:option).map { |option| option.text.tr("\n", '').strip }
          end
        end
      end
    end
  end
end
