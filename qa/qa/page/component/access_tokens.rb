# frozen_string_literal: true
require 'date'

module QA
  module Page
    module Component
      module AccessTokens
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.class_eval do
            include QA::Page::Component::ConfirmModal
          end

          base.view 'app/assets/javascripts/vue_shared/access_tokens/components/access_token.vue' do
            element 'created-access-token-field'
          end

          base.view 'app/assets/javascripts/vue_shared/access_tokens/components/access_tokens.vue' do
            element 'add-new-token-button'
          end

          base.view 'app/assets/javascripts/vue_shared/access_tokens/components/access_token_form.vue' do
            element 'create-token-button'
            element 'access-token-name-field'
            element 'expiry-date-field'
            element 'api-checkbox', '${scope.value}-checkbox' # rubocop:disable QA/ElementWithPattern
          end

          base.view 'app/assets/javascripts/access_tokens/components/expires_at_field.vue' do
            element 'expiry-date-field'
          end

          base.view 'app/views/shared/access_tokens/_form.html.haml' do
            element 'access-token-name-field'
            element 'create-token-button'
          end

          base.view 'app/views/shared/tokens/_scopes_form.html.haml' do
            element 'api-checkbox', '#{scope}-checkbox' # rubocop:disable QA/ElementWithPattern, Lint/InterpolationCheck
          end

          base.view 'app/assets/javascripts/access_tokens/components/new_access_token_app.vue' do
            element 'created-access-token-field'
          end

          base.view 'app/assets/javascripts/access_tokens/components/access_token_table_app.vue' do
            element 'revoke-button'
          end

          base.view 'app/views/user_settings/personal_access_tokens/index.html.haml' do
            element 'add-new-token-button'
          end

          base.view 'app/views/projects/settings/access_tokens/index.html.haml' do
            element 'add-new-token-button'
          end

          base.view 'app/views/groups/settings/access_tokens/index.html.haml' do
            element 'add-new-token-button'
          end

          base.view 'app/views/admin/impersonation_tokens/index.html.haml' do
            element 'add-new-token-button'
          end
        end

        def click_add_new_token_button
          dismiss_duo_chat_popup if respond_to?(:dismiss_duo_chat_popup)

          click_element('add-new-token-button')
        end

        def fill_token_name(name)
          fill_element('access-token-name-field', name)
        end

        def check_api
          check_element('api-checkbox', true)
        end

        def click_create_token_button
          click_element('create-token-button')
        end

        def created_access_token
          find_element('created-access-token-field').value
        end

        def fill_expiry_date(date)
          date = date.to_s if date.is_a?(Date)
          begin
            Date.strptime(date, '%Y-%m-%d')
          rescue ArgumentError
            raise "Expiry date must be in YYYY-MM-DD format"
          end

          fill_element('expiry-date-field', date)
        end

        def first_token_row_for_name(token_name)
          page.find('tr', text: token_name, match: :first, wait: 1.0)
        end

        def revoke_first_token_with_name(token_name)
          within first_token_row_for_name(token_name) do
            click_element('revoke-button')
          end

          click_confirmation_ok_button
        end
      end
    end
  end
end
