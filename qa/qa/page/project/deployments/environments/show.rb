# frozen_string_literal: true

module QA
  module Page
    module Project
      module Deployments
        module Environments
          class Show < Page::Base
            view 'app/views/projects/environments/_external_url.html.haml' do
              element :view_deployment
            end

            def view_deployment(&block)
              new_window = window_opened_by { click_element(:view_deployment) }

              within_window(new_window, &block) if block
            end
          end
        end
      end
    end
  end
end
