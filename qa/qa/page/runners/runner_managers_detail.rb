# frozen_string_literal: true

module QA
  module Page
    module Runners
      class RunnerManagersDetail < Page::Base
        view "app/assets/javascripts/ci/runner/components/runner_managers.vue" do
          element "runner-managers"
        end

        view "app/assets/javascripts/vue_shared/components/crud_component.vue" do
          element "crud-collapse-toggle"
        end

        def expand_runners
          toggle_button = find_element("crud-collapse-toggle")
          toggle_button.click if toggle_button['aria-expanded'] == 'false'
        end

        def has_online_runner?
          expand_runners
          within_element("td-status") do
            has_element?("status-active-icon")
          end
        end
      end
    end
  end
end
