# frozen_string_literal: true

module QA
  module Page
    module Project
      module Operations
        module Environments
          class Index < Page::Base
            view 'app/assets/javascripts/environments/components/environment_item.vue' do
              element :environment_link, 'class="environment-name table-mobile-content"'
            end

            def go_to_environment(environment_name)
              wait(reload: false) do
                click_link(environment_name)
              end
            end
          end
        end
      end
    end
  end
end
