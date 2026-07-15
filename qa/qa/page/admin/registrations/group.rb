# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Registrations
        # Self-managed admin first-run onboarding, step 1 (/admin/registrations/groups/new).
        #
        # A fresh self-managed instance with no groups redirects an administrator's first
        # sign-in here (see app/controllers/sessions_controller.rb#should_redirect_to_sm_onboarding?).
        # The page renders a minimal layout without the super sidebar, which breaks
        # Page::Main::Menu validation, so the test framework must move past it before continuing.
        class Group < QA::Page::Base
          view 'app/views/admin/registrations/groups/new.html.haml' do
            element 'group-name'
            element 'project-name'
            element 'submit-button'
          end

          # Whether this onboarding step is currently displayed
          #
          # @param [Integer] wait seconds to wait for the page to appear
          # @return [Boolean]
          def shown?(wait: 0)
            has_element?('group-name', wait: wait)
          end

          # Create the first group (and required project). This clears the instance-wide
          # `Group.exists?` check that gates the redirect, so it does not recur on later
          # sign-ins. Routes to the profile step (/admin/registrations/profile).
          #
          # @param [String] group group name
          # @param [String] project project name
          # @return [void]
          def create_initial_group(
            group: "qa-onboarding-#{SecureRandom.hex(4)}",
            project: "qa-onboarding-#{SecureRandom.hex(4)}")
            fill_element('group-name', group)
            fill_element('project-name', project)
            click_element('submit-button')
            nil
          end
        end
      end
    end
  end
end
