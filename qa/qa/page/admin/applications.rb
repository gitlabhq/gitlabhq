# frozen_string_literal: true

module QA
  module Page
    module Admin
      class Applications < Page::Base
        view 'app/views/admin/applications/index.html.haml' do
          element 'new-application-button'
        end

        view 'app/views/admin/applications/_form.html.haml' do
          element 'name-field'
          element 'redirect-uri-field'
          element 'trusted-checkbox'
          element 'save-application-button'
        end

        view 'app/views/shared/tokens/_scopes_form.html.haml' do
          element 'api-label', '#{scope}-label' # rubocop:disable QA/ElementWithPattern, Lint/InterpolationCheck
        end

        view 'app/views/shared/doorkeeper/applications/_show.html.haml' do
          element 'application-id-field'
          element 'id-of-application-field'
        end

        # rubocop:disable Layout/LineLength -- Single line is more readable
        view 'app/assets/javascripts/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue' do
          element 'clipboard-button'
        end
        # rubocop:enable Layout/LineLength

        def click_new_application_button
          click_element 'new-application-button'
        end

        def fill_name(name)
          fill_element 'name-field', name
        end

        def fill_redirect_uri(redirect_uri)
          fill_element 'redirect-uri-field', redirect_uri
        end

        def set_trusted_checkbox(value)
          check_element 'trusted-checkbox', value
        end

        def set_scope(scope)
          click_element "#{scope}-label".to_sym
        end

        def save_application
          click_element 'save-application-button'
        end

        def get_secret_id
          find_element('clipboard-button')['data-clipboard-text']
        end

        def get_application_id
          find_element('application-id-field').value
        end

        # Returns the ID of the resource
        def get_id_of_application
          find_element('id-of-application-field', visible: false).value
        end
      end
    end
  end
end
