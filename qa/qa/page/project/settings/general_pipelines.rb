# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class GeneralPipelines < Page::Base
          include Common

          view 'app/views/projects/settings/ci_cd/_form.html.haml' do
            element :build_coverage_regex_field
            element :save_general_pipelines_changes_button
          end

          def configure_coverage_regex(pattern)
            fill_element :build_coverage_regex_field, pattern
            click_element :save_general_pipelines_changes_button
          end
        end
      end
    end
  end
end
