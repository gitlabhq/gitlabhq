# frozen_string_literal: true

module QA
  module Page
    module Admin
      class Applications < Page::Base
        view 'app/views/admin/applications/index.html.haml' do
          element :new_application_button
        end

        view 'app/views/admin/applications/_form.html.haml' do
          element :name_field
          element :redirect_uri_field
          element :trusted_checkbox
          element :save_application_button
        end

        view 'app/views/shared/tokens/_scopes_form.html.haml' do
          element :api_label, '#{scope}_label' # rubocop:disable QA/ElementWithPattern, Lint/InterpolationCheck
        end

        view 'app/views/shared/doorkeeper/applications/_show.html.haml' do
          element :application_id_field
          element :id_of_application_field
        end

        view 'app/assets/javascripts/vue_shared/components/form/input_copy_toggle_visibility.vue' do
          element :clipboard_button
        end

        def click_new_application_button
          click_element :new_application_button
        end

        def fill_name(name)
          fill_element :name_field, name
        end

        def fill_redirect_uri(redirect_uri)
          fill_element :redirect_uri_field, redirect_uri
        end

        def set_trusted_checkbox(value)
          check_element :trusted_checkbox, value
        end

        def set_scope(scope)
          click_element "#{scope}_label".to_sym
        end

        def save_application
          click_element :save_application_button
        end

        def get_secret_id
          find_element(:clipboard_button)['data-clipboard-text']
        end

        def get_application_id
          find_element(:application_id_field).value
        end

        # Returns the ID of the resource
        def get_id_of_application
          find_element(:id_of_application_field, visible: false).value
        end
      end
    end
  end
end
