# frozen_string_literal: true

module QA
  module Page
    module Runners
      class RunnerManagersDetail < Page::Base
        view "app/assets/javascripts/ci/runner/components/runner_managers_detail.vue" do
          element "runner-button"
        end

        def expand_runners
          find_element("runner-button").click
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
