# frozen_string_literal: true

module QA
  module Page
    module Project
      module Deployments
        module Environments
          class Index < Page::Base
            view 'app/assets/javascripts/environments/components/environment_item.vue' do
              element :environment_link
            end

            def click_environment_link(environment_name)
              click_element(:environment_link, text: environment_name)
            end
          end
        end
      end
    end
  end
end
