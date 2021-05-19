# frozen_string_literal: true

module QA
  module Page
    module Component
      module AccessTokens
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/access_tokens/components/expires_at_field.vue' do
            element :expiry_date_field
          end

          base.view 'app/views/shared/access_tokens/_form.html.haml' do
            element :access_token_name_field
            element :create_token_button
          end

          base.view 'app/views/shared/tokens/_scopes_form.html.haml' do
            element :api_checkbox, '#{scope}_checkbox' # rubocop:disable QA/ElementWithPattern, Lint/InterpolationCheck
          end

          base.view 'app/views/shared/access_tokens/_created_container.html.haml' do
            element :created_access_token
          end

          base.view 'app/views/shared/access_tokens/_table.html.haml' do
            element :revoke_button
          end
        end

        def fill_token_name(name)
          fill_element(:access_token_name_field, name)
        end

        def check_api
          check_element(:api_checkbox)
        end

        def click_create_token_button
          click_element(:create_token_button)
        end

        def created_access_token
          find_element(:created_access_token, wait: 30).value
        end

        def fill_expiry_date(date)
          date = date.to_s if date.is_a?(Date)
          Date.strptime(date, '%Y-%m-%d') rescue ArgumentError raise "Expiry date must be in YYYY-MM-DD format"

          fill_element(:expiry_date_field, date)
        end

        def has_token_row_for_name?(token_name)
          page.has_css?('tr', text: token_name, wait: 1.0)
        end

        def first_token_row_for_name(token_name)
          page.find('tr', text: token_name, match: :first, wait: 1.0)
        end

        def revoke_first_token_with_name(token_name)
          within first_token_row_for_name(token_name) do
            accept_confirm do
              click_element(:revoke_button)
            end
          end
        end
      end
    end
  end
end
