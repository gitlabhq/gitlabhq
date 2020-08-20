# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        class MetricsAndProfiling < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/admin/application_settings/metrics_and_profiling.html.haml' do
            element :performance_bar_settings_content
          end

          def expand_performance_bar(&block)
            expand_content(:performance_bar_settings_content) do
              Component::PerformanceBar.perform(&block)
            end
          end
        end
      end
    end
  end
end
