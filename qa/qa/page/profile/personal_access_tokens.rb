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

        def go_to_new_token_form
          if Runtime::Feature.enabled?(:granular_personal_access_tokens)
            page.visit "#{Runtime::Scenario.gitlab_address}/-/user_settings/personal_access_tokens/legacy/new"
          else
            page.visit "#{Runtime::Scenario.gitlab_address}/-/user_settings/personal_access_tokens"
            click_add_new_token_button
          end
        end
      end
    end
  end
end
