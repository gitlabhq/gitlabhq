# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Registrations
        # Self-managed admin first-run onboarding, step 2 (/admin/registrations/profile).
        #
        # Reached after the group step. Like the group step it renders a minimal layout
        # without the super sidebar; submitting it routes the admin to the dashboard
        # (the new project, or root), where Page::Main::Menu validation can succeed.
        #
        # Only required fields are filled. The EE email opt-in checkbox is optional and
        # left untouched. `email` is required and not pre-filled, so it is always filled.
        # The EE `country` select is required but absent on CE.
        class Profile < QA::Page::Base
          view 'app/views/admin/registrations/profiles/new.html.haml' do
            element 'first-name'
            element 'last-name'
            element 'email'
            element 'organization-name'
            element 'submit-button'
          end

          # Whether this onboarding step is currently displayed
          #
          # @param [Integer] wait seconds to wait for the page to appear
          # @return [Boolean]
          def shown?(wait: 0)
            has_element?('first-name', wait: wait)
          end

          # Fill the required profile fields and continue to the dashboard.
          #
          # @param [String] first_name
          # @param [String] last_name
          # @param [String] organization
          # @return [void]
          def complete(first_name: 'QA', last_name: 'Onboarding', organization: 'QA Onboarding')
            fill_element('first-name', first_name)
            fill_element('last-name', last_name)
            fill_element('organization-name', organization)
            fill_email
            select_first_country

            click_element('submit-button')
            nil
          end

          private

          # The onboarding form deliberately does not pre-fill the admin's email, so this
          # always supplies one.
          def fill_email
            fill_element('email', "qa-onboarding-#{SecureRandom.hex(4)}@example.com")
          end

          # No-op in CE; overridden by EE::Page::Admin::Registrations::Profile when prepended
          def select_first_country; end
        end
      end
    end
  end
end

QA::Page::Admin::Registrations::Profile.prepend_mod_with('Page::Admin::Registrations::Profile', namespace: QA)
