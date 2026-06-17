# frozen_string_literal: true

require 'date'

module QA
  module Page
    module Profile
      class PersonalAccessTokens < Page::Base
        include Page::Component::AccessTokens

        view 'app/assets/javascripts/personal_access_tokens/components/created_personal_access_token.vue' do
          element 'created-access-token-field'
        end

        view 'app/assets/javascripts/personal_access_tokens/components/create_personal_access_token_dropdown.vue' do
          element 'create-token-dropdown'
          element 'create-legacy-token-item'
        end

        def go_to_new_token_form
          page.visit "#{Runtime::Scenario.gitlab_address}/-/user_settings/personal_access_tokens"

          # Detect the granular_personal_access_tokens UI by element
          # Flag disabled (default): the classic index shows the create button.
          # Flag enabled: the granular index shows the create dropdown, so open it and choose the legacy token form.
          case feature_flag_controlled_element(
            :granular_personal_access_tokens,
            'create-token-dropdown',
            'add-new-token-button'
          )
          when 'add-new-token-button'
            click_add_new_token_button
          else
            click_button('Generate token')
            click_element('create-legacy-token-item')
          end
        end
      end
    end
  end
end
