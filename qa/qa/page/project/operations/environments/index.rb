# frozen_string_literal: true

module QA
  module Page
    module Project
      module Operations
        module Environments
          class Index < Page::Base
            view 'app/assets/javascripts/environments/components/environment_item.vue' do
              element :environment_link
            end

            def click_environment_link(environment_name)
              wait(reload: false) do
                find(element_selector_css(:environment_link), text: environment_name).click
              end
            end
          end
        end
      end
    end
  end
end
