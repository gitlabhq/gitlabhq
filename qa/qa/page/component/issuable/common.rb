# frozen_string_literal: true

module QA
  module Page
    module Component
      module Issuable
        module Common
          def self.included(base)
            base.view 'app/assets/javascripts/issue_show/components/title.vue' do
              element :edit_button
              element :title, required: true
            end

            base.view 'app/assets/javascripts/issue_show/components/fields/title.vue' do
              element :title_input
            end

            base.view 'app/assets/javascripts/issue_show/components/fields/description.vue' do
              element :description_textarea
            end

            base.view 'app/assets/javascripts/issue_show/components/edit_actions.vue' do
              element :save_button
              element :delete_button
            end
          end
        end
      end
    end
  end
end
